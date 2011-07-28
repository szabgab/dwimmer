#!/usr/bin/perl
use strict;
use warnings;

use DBIx::RunSQL;
use Email::Valid;
use File::Spec;
use Getopt::Long qw(GetOptions);
use String::Random;
use Pod::Usage  qw(pod2usage);

use Dwimmer::Tools qw(get_dbfile sha1_base64);

my %opt;
GetOptions(\%opt,
    'email=s',
    'password=s',
    'root=s',
);
usage() if not $opt{email};
die 'Invalid e-mail' if not Email::Valid->address($opt{email});
usage() if not $opt{password};
die 'Password needs to be 6 characters' if length $opt{password} < 6;
usage() if not $opt{root};

my $sql = File::Spec->catfile('share', 'schema', 'dwimmer.sql');
my $dbfile = "$opt{root}/db/dwimmer.db"; #get_dbfile();
die "Database file '$dbfile' already exists\n" if -e $dbfile;

DBIx::RunSQL->create(
    dsn => "dbi:SQLite:dbname=$dbfile",
    sql => $sql,
    verbose => 0,
);

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
my $time = time;
my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
$dbh->do('INSERT INTO user (name, sha1, email, validation_key, verified) VALUES(?, ?, ?, ?, ?)', 
    {}, 
    'admin', sha1_base64($opt{password}), $opt{email}, $validation_key, 1);

print <<"END_MSG";
Database created.

You can now launch the application and visit the web site
END_MSG

exit;


sub usage {
    pod2usage();
}

=head1 SYNOPSIS

REQUIRED PARAMETERS:

   --email email        of administrator

   --password PASSWORD  of administrator

   --root ROOT         path to the root of the installation

=cut

