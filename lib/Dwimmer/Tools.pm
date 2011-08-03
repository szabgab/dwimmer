package Dwimmer::Tools;
use strict;
use warnings;
use Dancer ':syntax';

use base 'Exporter';
use Digest::SHA;
use YAML;


our @EXPORT_OK = qw(get_dbfile sha1_base64 _get_db _get_site);

sub _get_db {
    my $dbfile = path(config->{appdir}, 'db', 'dwimmer.db');
    Dwimmer::DB->connect("dbi:SQLite:dbname=$dbfile", '', '');
};

sub _get_site {
    my $site_name = 'www';

    # based on hostname?
    my $host = request->host;
    if ($host =~ /^([\w-]+)\./) {
        $site_name = $1;
    }

    my $db = _get_db();
    my $site = $db->resultset('Site')->find( { name => $site_name } );

    return ($site_name, $site);
}


sub get_dbfile {
	my $config = YAML::LoadFile('config.yml');
	my $dbfile = $config->{dwimmer}{dbfile};
	return $dbfile;
}

sub sha1_base64 {
	return Digest::SHA::sha1_base64( shift );
}

1;
