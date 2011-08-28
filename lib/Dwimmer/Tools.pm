package Dwimmer::Tools;
use strict;
use warnings;
use Dancer ':syntax';

use base 'Exporter';
use Digest::SHA;
use YAML;

use Dwimmer::DB;

our @EXPORT_OK = qw(sha1_base64 _get_db _get_site save_page);

our $dbfile;

sub _get_db {

    if (config->{appdir}) {
        $dbfile = path(config->{appdir}, 'db', 'dwimmer.db');
    }

    die "Could not figure out dbfile" if not $dbfile;

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


sub sha1_base64 {
	return Digest::SHA::sha1_base64( shift );
}

sub save_page {
    my ($site_id, $params) = @_;
    
    # TODO check if the user has the right to save this page!
    my $db = _get_db();
    my $cpage = $db->resultset('Page')->find({ siteid => $site_id, filename => $params->{filename} });

    my $create = $params->{create};
    if ($cpage and $create) {
            return to_json { error => 'page_already_exists' };
    }
    if (not $cpage and not $create) {
        return to_json { error => 'page_does_not_exist' };
    }

    # TODO transaction!
    my $revision = 1;
    if ($cpage) {
            $revision = $cpage->revision + 1;
            $cpage->revision( $revision );
            $cpage->update;
    } else {
            $cpage = $db->resultset('Page')->create({
                filename => $params->{filename},
                siteid   => $site_id,
                revision => $revision,
            });
    }


    my $time = time;
    $db->resultset('PageHistory')->create({
        pageid    => $cpage->id,
        title     => $params->{editor_title},
        filename  => $params->{filename},
        body      => $params->{editor_body},
        author    => $params->{author},
        siteid    => $site_id,
        timestamp => $time,
        revision  => $revision,
    });
    return to_json { success => 1 };
};

1;
