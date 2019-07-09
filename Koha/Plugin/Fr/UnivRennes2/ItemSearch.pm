package Koha::Plugin::Fr::UnivRennes2::ItemSearch;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use base qw(Koha::Plugins::Base);
use utf8;
# use Mojo::JSON qw(decode_json);

use CGI;

use JSON;

use C4::Auth;
use C4::Output;
use C4::Items;
use C4::Biblio;
use C4::Koha;

use Koha::AuthorisedValues;
use Koha::Biblios;
use Koha::Item::Search::Field qw(GetItemSearchFields);
use Koha::ItemTypes;
use Koha::Libraries;
use Koha::Plugin::Fr::UnivRennes2::CheckSudoc::Sudoc;


our $VERSION = '0.3';

our $metadata = {
    name            => 'Items search plugin for Koha',
    author          => 'Julien Sicot',
    date_authored   => '2019-07-09',
    date_updated    => '2019-07-09',
    minimum_version => '18.110000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin implements a specific items search module in Koha intranet'
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub uninstall() {
    my ( $self, $args ) = @_;

}

sub intranet_js {
    my ( $self ) = @_;

    return q|
        <script>$(document).ready(function() {
        		$("ul#toplevelmenu  > li.dropdown:eq(0) ul.dropdown-menu > li:nth-child(2)").after('<li><a href="/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3AFr%3A%3AUnivRennes2%3A%3AItemSearch&method=tool">Recherche d\'exemplaires am&eacute;lior&eacute;e</a></li>');
        	});
        </script>
    |;
}


sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};
    
    my $PluginClass='Koha::Plugin::Fr::UnivRennes2::ItemSearch';
	my $sudoc ='Koha::Plugin::Fr::UnivRennes2::CheckSudoc::Sudoc';
	my $PluginDir = C4::Context->config("pluginsdir");
	$PluginDir = $PluginDir.'/Koha/Plugin/Fr/UnivRennes2/ItemSearch';
	my %params = $cgi->Vars;
	
	my $format = $cgi->param('format');
	my $action = $cgi->param('action');
	my $template_name = '/tmpl/items-search.tt';
	
	if (defined $format and $format eq 'json') {
	    $template_name = '/tmpl/items-search_json.tt';
	
	    # Map DataTables parameters with 'regular' parameters
	    $cgi->param('rows', scalar $cgi->param('iDisplayLength'));
	    $cgi->param('page', (scalar $cgi->param('iDisplayStart') / scalar $cgi->param('iDisplayLength')) + 1);
	    my @columns = split /,/, scalar $cgi->param('sColumns');
	    $cgi->param('sortby', $columns[ scalar $cgi->param('iSortCol_0') ]);
	    $cgi->param('sortorder', scalar $cgi->param('sSortDir_0'));
	
	    my @f = $cgi->multi_param('f');
	    my @q = $cgi->multi_param('q');
	    push @q, '' if @q == 0;
	    my @op = $cgi->multi_param('op');
	    my @c = $cgi->multi_param('c');
	    my $iColumns = $cgi->param('iColumns');
	    foreach my $i (0 .. ($iColumns - 1)) {
	        my $sSearch = $cgi->param("sSearch_$i");
	        if (defined $sSearch and $sSearch ne '') {
	            my @words = split /\s+/, $sSearch;
	            foreach my $word (@words) {
	                push @f, $columns[$i];
	                push @c, 'and';
	
	                if ( grep /^$columns[$i]$/, qw( ccode homebranch holdingbranch location itemtype itype notforloan itemlost withdrawn paidfor itemnotes materials dateaccessioned datelastborrowed datelastseen) ) {
	                    push @q, "$word";
	                    push @op, '=';
	                } else {
	                    push @q, "%$word%";
	                    push @op, 'like';
	                }
	            }
	        }
	    }
	    $cgi->param('f', @f);
	    $cgi->param('q', @q);
	    $cgi->param('op', @op);
	    $cgi->param('c', @c);
	} elsif (defined $format and $format eq 'csv') {
	    $template_name = '/tmpl/items-search_csv.tt';
	
	    # Retrieve all results
	    $cgi->param('rows', 0);
	} elsif (defined $format and $format eq 'barcodes') {
	    # Retrieve all results
	    $cgi->param('rows', 0);
	} elsif (defined $format) {
	    die "Unsupported format $format";
	}
	
	

		
	my ($template, $borrowernumber, $cookie) = get_template_and_user({
	    template_name => $PluginDir.$template_name,
	    query => $cgi,
	    type => 'intranet',
	    authnotrequired => 0,
	    flagsrequired   => { catalogue => 1 },
	});
	
	my $mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.notforloan', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $notforloan_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.location', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $location_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.itemlost', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $itemlost_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.withdrawn', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $withdrawn_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.paidfor', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $paidfor_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'biblioitems.itemtype', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $itemtype_values = $mss->count ? GetAuthorisedValues($mss->next->authorised_value) : [];
	

	if (defined $action and $action eq 'searchitems') {
	    # Parameters given, it's a search
	
	    my $filter = {
	        conjunction => 'AND',
	        filters => [],
	    };
	
	    foreach my $p (qw(homebranch holdingbranch location itemtype itype ccode issues datelastborrowed notforloan itemlost withdrawn paidfor itemnotes materials dateaccessioned datelastborrowed datelastseen)) {
	        if (my @q = $cgi->multi_param($p)) {
	            if ($q[0] ne '') {
	                my $f = {
	                    field => $p,
	                    query => \@q,
	                };
	                if (my $op = scalar $cgi->param($p . '_op')) {
	                    $f->{operator} = $op;
	                }
	                push @{ $filter->{filters} }, $f;
	            }
	        }
	    }
	
	    my @c = $cgi->multi_param('c');
	    my @fields = $cgi->multi_param('f');
	    my @q = $cgi->multi_param('q');
	    my @op = $cgi->multi_param('op');
	
	    my $f;
	    for (my $i = 0; $i < @fields; $i++) {
	        my $field = $fields[$i];
	        my $q = shift @q;
	        my $op = shift @op;
	        if (defined $q and $q ne '') {
	            if ($i == 0) {
	                if (C4::Context->preference("marcflavour") ne "UNIMARC" && $field eq 'publicationyear') {
	                    $field = 'copyrightdate';
	                }
	                $f = {
	                    field => $field,
	                    query => $q,
	                    operator => $op,
	                };
	            } else {
	                my $c = shift @c;
	                $f = {
	                    conjunction => $c,
	                    filters => [
	                        $f, {
	                            field => $field,
	                            query => $q,
	                            operator => $op,
	                        }
	                    ],
	                };
	            }
	        }
	    }
	    push @{ $filter->{filters} }, $f;
	
	    # Yes/No parameters
	    foreach my $p (qw( damaged )) {
	        my $v = $cgi->param($p) // '';
	        my $f = {
	            field => $p,
	            query => 0,
	        };
	        if ($v eq 'yes') {
	            $f->{operator} = '!=';
	            push @{ $filter->{filters} }, $f;
	        } elsif ($v eq 'no') {
	            $f->{operator} = '=';
	            push @{ $filter->{filters} }, $f;
	        }
	    }
	
	    if (my $itemcallnumber_from = scalar $cgi->param('itemcallnumber_from')) {
	        push @{ $filter->{filters} }, {
	            field => 'itemcallnumber',
	            query => $itemcallnumber_from,
	            operator => '>=',
	        };
	    }
	    if (my $itemcallnumber_to = scalar $cgi->param('itemcallnumber_to')) {
	        push @{ $filter->{filters} }, {
	            field => 'itemcallnumber',
	            query => $itemcallnumber_to,
	            operator => '<=',
	        };
	    }
	
	    my $sortby = $cgi->param('sortby') || 'itemnumber';
	    if (C4::Context->preference("marcflavour") ne "UNIMARC" && $sortby eq 'publicationyear') {
	        $sortby = 'copyrightdate';
	    }
	    my $search_params = {
	        rows => scalar $cgi->param('rows') // 20,
	        page => scalar $cgi->param('page') || 1,
	        sortby => $sortby,
	        sortorder => scalar $cgi->param('sortorder') || 'asc',
	    };
	
	    my ($results, $total_rows) = SearchItems($filter, $search_params);
	
	    if ($format eq 'barcodes') {
	        print $cgi->header({
	            type => 'text/plain',
	            attachment => 'barcodes.txt',
	        });
	
	        foreach my $item (@$results) {
	            print $item->{barcode} . "\n";
	        }
	        exit;
	    }
	
	    if ($results) {
	        # Get notforloan labels
	        my $notforloan_map = {};
	        foreach my $nfl_value (@$notforloan_values) {
	            $notforloan_map->{$nfl_value->{authorised_value}} = $nfl_value->{lib};
	        }
	
	        # Get location labels
	        my $location_map = {};
	        foreach my $loc_value (@$location_values) {
	            $location_map->{$loc_value->{authorised_value}} = $loc_value->{lib};
	        }
	
	        # Get itemlost labels
	        my $itemlost_map = {};
	        foreach my $il_value (@$itemlost_values) {
	            $itemlost_map->{$il_value->{authorised_value}} = $il_value->{lib};
	        }
	        
	        # Get withdrawn labels
	        my $withdrawn_map = {};
	        foreach my $il_value (@$withdrawn_values) {
	            $withdrawn_map->{$il_value->{authorised_value}} = $il_value->{lib};
	        }
	        
	        # Get paidfor labels
	        my $paidfor_map = {};
	        foreach my $il_value (@$paidfor_values) {
	            $paidfor_map->{$il_value->{authorised_value}} = $il_value->{lib};
	        }
	        
	        # Get doctype labels
	        my $itemtype_map = {};
	        foreach my $il_value (@$itemtype_values) {
	            $itemtype_map->{$il_value->{authorised_value}} = $il_value->{lib};
	        }
	
	        foreach my $item (@$results) {
	            my $biblio = Koha::Biblios->find( $item->{biblionumber} );
	            $item->{biblio} = $biblio;
	            $item->{biblioitem} = $biblio->biblioitem->unblessed;
	            $item->{status} = $notforloan_map->{$item->{notforloan}};
	            if (defined $item->{location}) {
	                $item->{location} = $location_map->{$item->{location}};
	            }
	            
	            my $biblioitem = $item->{biblioitem} ;
	            my $ppn = $biblioitem->{lccn};
	            
	            my $sudocrun = scalar $cgi->param('sudocRun');
	            
	            if (defined $sudocrun and $sudocrun eq "sudocRun"){
		            if (defined $ppn and length $ppn){
			          if (($sudoc->getRcrFromPpn($ppn) ne "error") && $sudoc->getRcrFromPpn($ppn) ne "null") {
			           my (@rcr) = $sudoc->getRcrFromPpn($ppn);
		               if( @rcr >= 1 ){
		                    my $rcr_count = scalar(@rcr); 
		            	    $item->{sudoc_other} = $rcr_count;
		                } 
					   }
					   else { $item->{sudoc_other} = "error" ; }
		
					  }
					else {
						 $item->{sudoc_other} = "";
					}
				}
				else {
						 $item->{sudoc_other} = "";
					}
				            
	
				my $count = $PluginClass->get_totalitems($item->{biblionumber});
				$item->{totalitems} = $count;
	
	            
	        }
	    }
	
	    $template->param(
	        filter => $filter,
	        search_params => $search_params,
	        results => $results,
	        total_rows => $total_rows,
	    );
	
	    if ($format eq 'csv') {
	        print $cgi->header({
	            type => 'text/csv',
	            attachment => 'items.csv',
	        });
	
	        for my $line ( split '\n', $template->output ) {
	            print "$line\n" unless $line =~ m|^\s*$|;
	        }
	    } elsif ($format eq 'json') {
	        $template->param(sEcho => scalar $cgi->param('sEcho'));
	        output_with_http_headers $cgi, $cookie, $template->output, 'json';
	    }
	
	    exit;
	}






	# Display the search form
	
	my @branches = map { value => $_->branchcode, label => $_->branchname }, Koha::Libraries->search( {}, { order_by => 'branchname' } );
	my @locations;
	foreach my $location (@$location_values) {
	    push @locations, {
	        value => $location->{authorised_value},
	        label => $location->{lib} // $location->{authorised_value},
	    };
	}
	my @itypes;
	foreach my $itype ( Koha::ItemTypes->search ) {
	    push @itypes, {
	        value => $itype->itemtype,
	        label => $itype->translated_description,
	    };
	}
	
	$mss = Koha::MarcSubfieldStructures->search({ frameworkcode => '', kohafield => 'items.ccode', authorised_value => [ -and => {'!=' => undef }, {'!=' => ''}] });
	my $ccode_avcode = $mss->count ? $mss->next->authorised_value : 'CCODE';
	my $ccodes = GetAuthorisedValues($ccode_avcode);
	my @ccodes;
	foreach my $ccode (@$ccodes) {
	    push @ccodes, {
	        value => $ccode->{authorised_value},
	        label => $ccode->{lib},
	    };
	}
	
	my @notforloans;
	foreach my $value (@$notforloan_values) {
	    push @notforloans, {
	        value => $value->{authorised_value},
	        label => $value->{lib},
	    };
	}
	
	my @itemlosts;
	foreach my $value (@$itemlost_values) {
	    push @itemlosts, {
	        value => $value->{authorised_value},
	        label => $value->{lib},
	    };
	}
	
	my @withdrawns;
	foreach my $value (@$withdrawn_values) {
	    push @withdrawns, {
	        value => $value->{authorised_value},
	        label => $value->{lib},
	    };
	}
	
	my @itemtypes;
	foreach my $value (@$itemtype_values) {
	    push @itemtypes, {
	        value => $value->{authorised_value},
	        label => $value->{lib},
	    };
	}
	
	my @paidfors;
	foreach my $value (@$paidfor_values) {
	    push @paidfors, {
	        value => $value->{authorised_value},
	        label => $value->{lib},
	    };
	}
	
	my @items_search_fields = GetItemSearchFields();
	
	my $authorised_values = {};
	foreach my $field (@items_search_fields) {
	    if (my $category = ($field->{authorised_values_category})) {
	        $authorised_values->{$category} = GetAuthorisedValues($category);
	    }
	}
	
	$template->param(
	    branches => \@branches,
	    locations => \@locations,
	    itypes => \@itypes,
	    itemtypes => \@itemtypes,
	    ccodes => \@ccodes,
	    notforloans => \@notforloans,
	    itemlosts => \@itemlosts,
	    withdrawns => \@withdrawns,
	    paidfors => \@paidfors,
	    items_search_fields => \@items_search_fields,
	    authorised_values_json => to_json($authorised_values),
	);
	
	output_html_with_http_headers $cgi, $cookie, $template->output;
     
}

# sub api_routes {
#     my ( $self, $args ) = @_;
# 
#     my $spec_str = $self->mbf_read('openapi.json');
#     my $spec     = decode_json($spec_str);
# 
#     return $spec;
# }
# 
# sub api_namespace {
#     my ( $self ) = @_;
# 
#     return 'univrennes2_fr';
# }

sub get_totalitems {
    my ( $self, $itemnumber ) = @_;
    
    my $dbh = C4::Context->dbh;
    my $query = "SELECT COUNT(itemnumber) as count FROM items i WHERE i.biblionumber = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute( $itemnumber );
	my ($count) = $sth->fetchrow();
	return $count;

}

1;