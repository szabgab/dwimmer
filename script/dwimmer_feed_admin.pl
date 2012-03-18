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

	'listconfig',
	'config=s',
	'unconfig=s',
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
} elsif ($opt{listconfig}) {
	$admin->list_config();
} elsif ($opt{unconfig}) {
	$admin->db->delete_config( $opt{unconfig} );
} elsif ($opt{config}) {
	my $value = shift;
	usage('') if not defined $value;
	$admin->db->set_config( $opt{config}, $value);
} else {
	usage();
}


sub usage {
	my $text = shift || '';

	die <<"END_USAGE";
$text

Usage: $0
       --store storage.db

       --add

       --list [filter]
       --enable ID
       --disable ID

       --update ID "feed=http://..."
       --update ID "comment=some text here"
       --update ID "twitter=twitter_id"

       --listconfig
       --config key value
       --unconfig key
END_USAGE
}
