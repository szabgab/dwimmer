#!/usr/bin/perl
use strict;
use warnings;

use Cwd qw(abs_path);
use DBIx::Class::Schema::Loader qw(make_schema_at);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);

my $lib;
BEGIN {
	$lib = File::Spec->catdir( dirname(dirname abs_path($0)), 'lib');
}
use lib $lib;

#use Dwimmer::Tools;

my $root = tempdir( CLEANUP => 0 );
mkdir "$root/db";
system "$^X -I$lib script/dwimmer_setup.pl --email dev\@dwimmer.org --password dwimmer --root $root";

my $dbfile = "$root\\db\\dwimmer.db";

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
