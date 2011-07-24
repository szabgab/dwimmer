#!/usr/bin/perl
use strict;
use warnings;

use DBIx::Class::Schema::Loader qw(make_schema_at);

use Dwimmer::Tools;

my $dbfile = Dwimmer::Tools->get_dbfile;

make_schema_at(
	'Dwimmer::DB',
	{
		debug => 0,
		dump_directory => './lib',
	},
	[
		"dbi:SQLite:dbname=$dbfile", "", "",
	],
);
