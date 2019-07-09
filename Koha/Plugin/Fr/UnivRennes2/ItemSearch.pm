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
use Mojo::JSON qw(decode_json);

use CGI;


our $VERSION = '{VERSION}';

our $metadata = {
    name            => 'Items search plugin for Koha',
    author          => 'Julien Sicot',
    date_authored   => '2019-07-09',
    date_updated    => '{UPDATE_DATE}',
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
        		$("ul#toplevelmenu  > li.dropdown:eq(0) ul.dropdown-menu > li:nth-child(2)").after('<li><a href="/plugin/Koha/Plugin/Fr/UnivRennes2/ItemSearch/intranet/items-search.pl">Recherche d\'exemplaires am&eacute;lior&eacute;e</a></li>');
        	});
        </script>
    |;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;

    return 'univrennes2_fr';
}

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