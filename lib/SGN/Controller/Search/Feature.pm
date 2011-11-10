package SGN::Controller::Search::Feature;
use Moose;
use namespace::autoclean;

use SGN::View::Feature 'location_string';

use URI::FromHash 'uri';
use YAML::Any;
use JSON;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::Component::ApplicationAttribute';

has 'default_page_size' => (
    is      => 'ro',
    default => 20,
);

=head1 PUBLIC ACTIONS

=head2 search

Interactive search interface for features.

Public path: /search/features

=cut

sub oldsearch : Path('/feature/search') Args(0) {
    $_[1]->res->redirect( '/search/features', 301 );
}

sub search :Path('/search/features') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        template => '/feature/search.mas',
    );
    $c->forward('View::Mason');
}

sub search_json :Path('/search/features/search_service') Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;
    $c->stash->{search_args} = {
        map {
            $_ => $params->{$_},
        } qw( organism type type_id name srcfeature_id srcfeature_start srcfeature_end )
    };

    my $rs = $c->forward('make_feature_search_rs');

    my $total = $rs->count;

    # set up prefetching, sorting, and paging
    $rs = $rs->search(
        undef,
        {
          #prefetch => [ 'type', 'organism', { 'featureloc_features' => 'srcfeature' } ],
          prefetch => [ 'type', 'organism' ],
          page => $params->{'page'} || 1,
          rows => $params->{'limit'} || $self->default_page_size,
          order_by => {
              '-'.(lc $params->{dir} || 'asc' )
              =>
              ( {
                  'type'     => 'type.name',
                  'organism' => 'organism.species',
                  'name'     => 'me.name',
                }->{lc $params->{'sort'}}
                || 'me.feature_id'
              )
          },
        },
      );

    $c->res->body( to_json( {
        success    => JSON::true,
        totalCount => $total,
        data => [
            map { {
                organism   => $_->organism->species,
                type       => $_->type->name,
                name       => $_->name,
                feature_id => $_->feature_id,
                seqlen     => $_->seqlen,
                locations  => ( join( ',', map {
                                    my $fl = $_;
                                    location_string( $fl )
                                } $_->featureloc_features
                              ),
                ),
            } }
            $rs->all
        ],
    }));

}

sub type_autocomplete : Path('/search/features/feature_types_service') {
    my ( $self, $c ) = @_;

    my $types = $c->dbc->dbh->selectall_arrayref(<<'' );
SELECT cvterm_id, name
  FROM cvterm ct
 WHERE cvterm_id IN( SELECT DISTINCT type_id FROM feature )
ORDER BY name

    $c->res->content_type('text/json');
    $c->res->body( to_json( { success => JSON::true,
                              data => [
                                  map +{ type_id => $_->[0], name => $_->[1] }, @{ $types || [] }
                              ],
                             }
                          )
                 );

}

sub srcfeatures_autocomplete : Path('/search/features/srcfeatures_service') {
    my ( $self, $c ) = @_;

    my $srcfeatures = $c->dbc->dbh->selectall_arrayref(<<'' );
SELECT srcfeature_id, f.name, f.seqlen, count
FROM
    ( SELECT srcfeature_id, count(*) as count
      FROM featureloc
      GROUP BY srcfeature_id
      HAVING count(*) > 1
    ) as srcfeatures
JOIN feature f ON srcfeature_id = f.feature_id
ORDER BY f.name ASC
;

    $c->res->content_type('text/json');
    $c->res->body( to_json( { success => JSON::true,
                              data => [
                                  map +{ feature_id => $_->[0], name => $_->[1], seqlen => $_->[2], count => $_->[3] }, @{ $srcfeatures || [] }
                              ],
                             }
                          )
                 );
}

# assembles a DBIC resultset for the search based on the submitted
# form values
sub make_feature_search_rs : Private {
    my ( $self, $c ) = @_;

    my $args = $c->stash->{search_args};

    my $schema = $c->dbic_schema('Bio::Chado::Schema','sgn_chado');
    my $rs = $schema->resultset('Sequence::Feature');

    if( my $name = $args->{'name'} ) {
        $rs = $rs->search({ 'me.name' => { ilike => '%'.$name.'%' }});
    }

    if( my $type = $args->{'type'} ) {
        my $type_rs = $schema->resultset('Cv::Cvterm')
                             ->search({ 'lower(name)' => lc $type });
        $rs = $rs->search({ 'me.type_id' => { -in => $type_rs->get_column('cvterm_id')->as_query }});
    }

    if( my $type_id = $args->{'type_id'} ) {
        $rs = $rs->search({ 'me.type_id' => $type_id });
    }

    if( my $organism = $args->{'organism'} ) {
        my $organism_rs = $schema->resultset('Organism::Organism')
                                 ->search({ species => { -ilike => '%'.$organism.'%' }});
        $rs = $rs->search({ 'me.organism_id' => { -in => $organism_rs->get_column('organism_id')->as_query } });
    }

    if( my $srcfeature_id = $args->{'srcfeature_id'} ) {
        $rs = $rs->search({ 'featureloc_features.srcfeature_id' => $srcfeature_id }, { prefetch => 'featureloc_features' });
    }

    if( my $start = $args->{'srcfeature_start'} ) {
        $rs = $rs->search({ 'featureloc_features.fmax' => { '>=' => $start } }, { prefetch => 'featureloc_features' });
    }

    if( my $end = $args->{'srcfeature_end'} ) {
        $rs = $rs->search({ 'featureloc_features.fmin' => { '<=' => $end+1 } }, { prefetch => 'featureloc_features' });
    }

    $c->stash->{search_resultset} = $rs;
}

1;

