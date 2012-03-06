#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::Admin;

use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
	'store=s',

	'list:s',
) or usage();
usage() if not $opt{store};

my $admin = Dwimmer::Feed::Admin->new(%opt);
if (exists $opt{list}) {
	$admin->list( $opt{list} );
}


sub usage {
	die <<"END_USAGE";
Usage: $0 --store storage.db
       --list [filter]
END_USAGE
}
