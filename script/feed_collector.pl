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
) or usage();
usage() if not $opt{store} or not $opt{sources};

my $collector = Dwimmer::Feed::Collector->new(%opt);
$collector->collect();

sub LOG {
	print "@_\n";
}

sub usage {
	die "Usage: $0 --store storage.db  --sources sources.json\n";
}
