#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::Collector;
use Dwimmer::Feed::Sendmail;

use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
	'store=s',

	'collect',
	'sendmail',
	'html=s',
) or usage();
usage() if not $opt{store};
usage() if not $opt{collect} and not $opt{html} and not $opt{sendmail} and not $opt{twitter};

my $t0 = time;

my $collector = Dwimmer::Feed::Collector->new(%opt);

if ($opt{collect}) {
	$collector->collect();
}

if ($opt{html}) {
	$collector->generate_html( $opt{html} );
}

if ($opt{sendmail}) {
	my $mail = Dwimmer::Feed::Sendmail->new(%opt);
	$mail->send;
}

if ($opt{tweet}) {
	# TODO: tweet
}

my $t1 = time;
LOG("Elapsed time: " . ($t1-$t0));
exit;


sub LOG {
	print "@_\n";
}

sub usage {
	die "Usage: $0 --store storage.db  [--collect --sendmail --html DIR]\n";
}


