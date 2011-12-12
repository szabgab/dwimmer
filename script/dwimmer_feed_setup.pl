#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::DB;

use JSON         qw(from_json);
use File::Slurp  qw(read_file);


my $SCHEMA = <<'SCHEMA';
CREATE TABLE sources (
	id        INTEGER PRIMARY KEY,
	title     VARCHAR(100),
	url       VARCHAR(100) UNIQUE NOT NULL,
	feed      VARCHAR(100) UNIQUE NOT NULL,
	comment   BLOB,
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
)
SCHEMA

my ($store, $sources_json) = @ARGV;

my $db = Dwimmer::Feed::DB->new( store => $store );
$db->connect;

foreach my $sql (split /;/, $SCHEMA) {
	$db->dbh->do($sql);
}

my $sources = from_json scalar read_file $sources_json;
for my $e ( @{ $sources->{feeds}{entries} } ) {
	$db->add_source($e);
};
	
