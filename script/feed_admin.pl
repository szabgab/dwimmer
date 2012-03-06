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
	'update=i',
	'add',
) or usage();
usage() if not $opt{store};

my $admin = Dwimmer::Feed::Admin->new(%opt);
if (exists $opt{list}) {
	$admin->list( $opt{list} );
} elsif ( defined $opt{enable} ) {
	$admin->enable( $opt{enable} );
} elsif ( defined $opt{disable} ) {
	$admin->disable( $opt{disable} );
} elsif ( defined $opt{update} ) {
	my $str = shift;
	usage('Need update value') if not $str;
	my ($field, $value) = split /=/, $str;
	$admin->update($opt{update}, $field, $value);
} elsif (exists $opt{add}) {
	$admin->add;
}


sub usage {
	my $text = shift || '';

	die <<"END_USAGE";
$text

Usage: $0 --store storage.db

       --list [filter]
       --enable ID
       --disable ID

       --update ID "feed=http://..."
       --update ID "comment=some text here"
END_USAGE
}
