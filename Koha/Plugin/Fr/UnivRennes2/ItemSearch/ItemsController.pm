package Koha::Plugin::Fr::UnivRennes2::ItemSearch::ItemsController;

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

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Koha::Biblios;
use Koha::Checkouts;
use Koha::Holds;
use Koha::Item::Transfers;
use Koha::Items;
use Koha::Libraries;

=head1 Koha::Plugin::Fr::UnivRennes2::ItemSearch::ItemsController

A class implementing the controller methods for checking checkouts items

=head2 Class Methods

=head3 get_item

=cut

sub get_item {
    my $c = shift->openapi->valid_input or return;

    my $item_id = $c->validation->param('item_id');
    my $item    = Koha::Items->find($item_id);

    unless ($item) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    return $c->render( status => 200, openapi =>  $item );
}


1;