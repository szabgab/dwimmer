use strict;
use warnings;

use Data::Dumper;

use Dwimmer::Feed::DB;
use Dwimmer::Feed::Sendmail;

# just to send simple messages as the system would

my $cmd = shift;
if (not $cmd) {
    print "Usage:\n";
    print "       $0 list\n";
    print "       $0 N   (number)\n";
}

die "list not implemented yet\n" if $cmd eq 'list';
die "invalid command\n" if $cmd !~ /^\d+$/;

# TODO: these maybe should be accepted from the command line:
my %opt = (
    store => 't.db',
);

my $db = Dwimmer::Feed::DB->new( store => $opt{store} );
$db->connect;

my $sources = $db->get_sources;

my $mail = Dwimmer::Feed::Sendmail->new(%opt);
my $e = $db->get_entry($cmd);
#print Dumper $e;
$mail->send_entry($sources, $e);
sub LOG {}


