use strict;
use CXGN::Page;
my $page=CXGN::Page->new('quick_search.html','html2pl converter');
$page->header('SGN: Quick Search Help');
print<<END_HEREDOC;

  <center>
    
  <table summary="" width="720" cellpadding="0" cellspacing="0"
  border="0">
    <tr>
      <td>
        <center>
          <table summary="" width="720" cellpadding="0"
          cellspacing="0" border="0">
            <tr>
              <td>
                <h3>Quick Search Help</h3><p>The quick search
                functionality is part of the <a href=
                "toolbar.pl">toolbar</a> on top of almost every
                SGN web page. To use it, simply enter a search term
                in the text input box and click on the quick search
                button. The search can take a while depending on
                the actual word you search. Specifically, words
                that appear in many of the blast annotations, such
                'Arabidopsis', will increase search time.</p>

                <p>Quick search performs a series of searches in
                the database and displays a summary page of the
                matches. For each of the searches, a line is
                displayed with information how many entities were
                matched in the database.</p>

                <p>If entities were found in the database, a link
                is provided to complete the actual search. Click on
                that link to see the search results.</p>

                <p>The individual quick searches do the
                following:</p>

                <dl>
                  <dt><strong>Identifier searches</strong></dt>

                  <dd>Identifier searches perform exact match
                  searches on clone, est, unigene and marker
                  identifiers in the database</dd>

                  <dt><br /><strong>Annotation searches</strong></dt>

                  <dd>The annotation searches search the manual and
                  automatic annotation that are available for
                  unigenes. They report the number of annotations
                  and the number of corresponding unigenes that
                  were found. If there are more than 5000
                  annotation matches, the number of unigenes is not
                  reported to save on querying time.</dd>

                  <dt><br /><strong>People search</strong></dt>

                  <dd>Searches the last name as a sub-string match
                  in the SGN People Directory.</dd>

                  <dt><br /><strong>Library search</strong></dt>

                  <dd>Searches the libraries on name, tissue,
                  development stage, authors, and other fields as a
                  substring search.</dd>

                  <dt><br /><strong>SGN Pages search</strong></dt>

                  <dd>Performs a Google search on the
                  sgn.cornell.edu domain. Please note that when we
                  re-arrange pages on the SGN site, it may take
                  Google a number of days to re-index the site, so
                  sometimes the pages you find with this search
                  will not be valid. However, we will try to keep
                  site rearrangements to a minimum.</dd>

                  <dt><br /><strong>Pages on the entire web</strong></dt>

                  <dd>Performs a Google search without the
                  sgn.cornell.edu domain constraint. Searches the
                  entire web.</dd>
                </dl>
              </td>
            </tr>
          </table>
          
        </center>
      </td>
    </tr>
  </table>
</center>
END_HEREDOC
$page->footer();