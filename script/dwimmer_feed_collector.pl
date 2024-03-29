#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use Dwimmer::Feed::Collector;
use Dwimmer::Feed::Sendmail;

use Getopt::Long qw(GetOptions);
use MIME::Lite ();

my %opt;
GetOptions(
	\%opt,
	'store=s',

	'collect',
	'sendmail',
	'html',
	'verbose',
	'mailreport',
) or usage();
usage('Missing --store') if not $opt{store};
usage('At least one of --collect --html --sendmail is needed')
	if not $opt{collect} and not $opt{html} and not $opt{sendmail};    # and not $opt{twitter};

my $t0     = time;
LOG("Staring");

my $collector = Dwimmer::Feed::Collector->new(%opt);

if ( $opt{collect} ) {
	$collector->collect_all();
	if ( $collector->error ) {
        LOG("ERROR: ", $collector->error);
	    if ( $opt{mailreport} ) {
	    	#my $msg = MIME::Lite->new(
	    	#	From    => 'gabor@szabgab.com',
	    	#	To      => 'szabgab@gmail.com',
	    	#	Subject => 'Feed collector errors',
	    	#	Data    => $collector->error,
	    	#);
	    	#$msg->send;
	    }
    }
}

if ( $opt{html} ) {
	$collector->generate_html_all();
}

if ( $opt{sendmail} ) {
	my $mail = Dwimmer::Feed::Sendmail->new(%opt);
	$mail->send;
}

if ( $opt{twitter} ) {

	# TODO: tweet
}

my $t1           = time;
my $elapsed_time = $t1 - $t0;
LOG("Elapsed time: $elapsed_time");
exit;

sub LOG {
	return if not $opt{verbose};
    open(my $fh, ">>", "/etc/dwimmer.log")  or die "Could not open log file $!";
    my $time = localtime();
	print $fh "$time @_\n";
}

sub usage {
	my $txt = shift;
	if ($txt) {
		print STDERR "**** $txt\n\n";
	}
	print STDERR "Usage: $0 --store storage.db  [--collect --sendmail --html DIR]\n";
	exit 1;
}

