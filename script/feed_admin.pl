#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::Admin;

use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
	'store=s',

	'list:s',
	'enable=i',
	'disable=i',
) or usage();
usage() if not $opt{store};

my $admin = Dwimmer::Feed::Admin->new(%opt);
if (exists $opt{list}) {
	$admin->list( $opt{list} );
} elsif ( defined $opt{enable} ) {
	$admin->enable( $opt{enable} );
} elsif ( defined $opt{disable} ) {
	$admin->disable( $opt{disable} );
}


sub usage {
	die <<"END_USAGE";

Usage: $0 --store storage.db

       --list [filter]
       --enable ID
       --disable ID
END_USAGE
}
