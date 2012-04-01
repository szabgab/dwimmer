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

	'setup',

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

if ($opt{setup}) {
	setup($opt{store});
	exit;
}

usage("Database ($opt{store}) does NOT exist") if not -e $opt{store};

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
exit;
##############################

sub setup {
	my ($store) = @_;

	usage("Database ($store) already exists") if -e $store;

my $SCHEMA = <<'SCHEMA';
CREATE TABLE sources (
	id        INTEGER PRIMARY KEY,
	title     VARCHAR(100),
	url       VARCHAR(100) UNIQUE NOT NULL,
	feed      VARCHAR(100) UNIQUE NOT NULL,
	comment   BLOB,
	twitter   VARCHAR(30),
	status    VARCHAR(30)
);

CREATE TABLE entries (
	id        INTEGER PRIMARY KEY,
	source_id INTEGER NOT NULL,
	link      VARCHAR(100) UNIQUE NOT NULL,
	remote_id VARCHAR(100),
	author    VARCHAR(100),
	issued    VARCHAR(100),
	title     VARCHAR(100),
	summary   BLOB,
	content   BLOB,
	tags      VARCHAR(100),
	FOREIGN KEY (source_id) REFERENCES sources(id)
);
CREATE TABLE delivery_queue (
	channel  VARCHAR(30) NOT NULL,
	entry    INTEGER     NOT NULL,
	FOREIGN KEY (entry) REFERENCES entries(id)
);
CREATE TABLE config (
	key VARCHAR(100) UNIQUE NOT NULL,
	value VARCHAR(255)
)
SCHEMA

	my $db = Dwimmer::Feed::DB->new( store => $store );
	$db->connect;

	foreach my $sql (split /;/, $SCHEMA) {
		$db->dbh->do($sql);
	}
}


sub usage {
	my $text = shift || '';

	die <<"END_USAGE";
$text

Usage: $0
       --store storage.db

       --setup

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
