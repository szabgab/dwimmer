#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::DB;
use Dwimmer::Feed::Collector;
use Dwimmer::Feed::Sendmail;

use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
	'store=s',
	'sources=s',
	'sendmail',
) or usage();
usage() if not $opt{store} or not $opt{sources};

my $t0 = time;

my $collector = Dwimmer::Feed::Collector->new(%opt);
$collector->collect();

# TODO: generate html and feeds

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
	die "Usage: $0 --store storage.db  --sources sources.json\n";
}


# TODO: comprehensive link collection (sources: feeds, aggregators, twitter, reddit), delicious
# TODO: languages
# TODO: display summary of all, allow for javascript setting which language(s) to show
# TODO: display social icons with counters (Twitter, Reddit, Google+, FaceBook, HackerNews)


