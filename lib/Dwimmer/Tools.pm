package Dwimmer::Tools;
use Moose;

use YAML;

sub get_dbfile {
	my $config = YAML::LoadFile('config.yml');
	my $dbfile = $config->{dwimmer}{dbfile};
	return $dbfile;
}


1;
