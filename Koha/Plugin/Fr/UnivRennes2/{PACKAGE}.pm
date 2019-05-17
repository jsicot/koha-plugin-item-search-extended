package Koha::Plugin::Fr::UnivRennes2::{PACKAGE};

use utf8;
use Modern::Perl;
use base qw(Koha::Plugins::Base);

## Here we set our plugin version
our $VERSION = '{VERSION}';

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => '{NAME}',
    author          => '{AUTHOR}',
    date_authored   => '{CREATION_DATE}',
    date_updated    => '{UPDATE_DATE}',
    minimum_version => '{MIN_KOHA_VERSION}',
    maximum_version => undef,
    version         => $VERSION,
    description     => '{DESCRIPTION}',
};

sub new {
    my ( $class, $args ) = @_;
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;
    my $self = $class->SUPER::new($args);
    return $self;
}

#sub report {}
#sub tool {}
#sub to_marc {}
#sub opac_online_payment {}
#sub opac_online_payment_begin {}
#sub opac_online_payment_end {}
#sub opac_head {}
#sub opac_js {}
#sub intranet_head {}
#sub intranet_js {}
#sub intranet_catalog_biblio_enhancements_toolbar_button {}
#sub configure {}
#sub install {}
#sub upgrade {}
#sub uninstal {}
#sub api_routes {}
#sub api_namespace {}


1;
