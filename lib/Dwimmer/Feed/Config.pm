package Dwimmer::Feed::Config;
use strict;
use warnings;

sub get_config_hash {
	my ($self, $db) = @_;

	return $db->get_config_hash;
}

sub get_config {
	my ($self, $db) = @_;

	my $config = $db->get_config;
}


1;
