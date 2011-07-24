package Dwimmer::Tools;
use strict;
use warnings;

use base 'Exporter';
use Digest::SHA;
use YAML;

our @EXPORT_OK = qw(get_dbfile sha1_base64);


sub get_dbfile {
	my $config = YAML::LoadFile('config.yml');
	my $dbfile = $config->{dwimmer}{dbfile};
	return $dbfile;
}

sub sha1_base64 {
	return Digest::SHA::sha1_base64( shift );
}

1;
