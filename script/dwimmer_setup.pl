#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Cwd qw(abs_path);
use DBIx::RunSQL;
use Email::Valid;
use File::Basename qw(dirname);
use File::Copy::Recursive;
use File::Path qw(mkpath);
use File::Spec;
use File::ShareDir;
use Getopt::Long qw(GetOptions);
use String::Random;
use Pod::Usage  qw(pod2usage);

use Dwimmer::Tools qw(sha1_base64 save_page);

my %opt;
GetOptions(\%opt,
    'email=s',
    'password=s',
    'root=s',
    'dbonly',
    'silent',
    'share=s',
    'upgrade',
);
usage() if not $opt{email};
die 'Invalid e-mail' if not Email::Valid->address($opt{email});
usage() if not $opt{password};
die 'Password needs to be 6 characters' if length $opt{password} < 6;
usage() if not $opt{root};


if (-e $opt{root} and not $opt{dbonly} and not $opt{upgrade}) { 
    die "Root directory ($opt{root}) already exists"
}

if ($opt{upgrade} and not -e $opt{root}) {
    die "Root directory ($opt{root}) does NOT exist."
}

my $dist_dir;

# When we are in the development environment (have .git) set this to the root directory
# When we are in the installation environment (have Makefile.PL) set this to the root directory
if (grep { -e File::Spec->catdir(dirname(dirname abs_path($0)) , $_) } ('.git', 'Makefile.PL')) {
    $dist_dir = dirname(dirname abs_path($0))
} else {
    $dist_dir = File::ShareDir::dist_dir('Dwimmer');
}
# die $dist_dir;

my $db_dir = File::Spec->catdir($opt{root}, 'db');
mkpath $db_dir if not -e $db_dir;

if (not $opt{dbonly}) {
    foreach my $dir (qw(views public bin environments)) {
        File::Copy::Recursive::dircopy(
            File::Spec->catdir( $dist_dir, $dir), 
            File::Spec->catdir( $opt{root}, $dir )
        );
    }
    File::Copy::Recursive::fcopy(
            File::Spec->catdir( $dist_dir, 'config.yml'), 
            File::Spec->catdir( $opt{root} )
        );
}

my $dbfile = File::Spec->catfile( $db_dir, 'dwimmer.db' );
if (not $opt{upgrade}) {
    setup_db($dbfile);
}

my @upgrade_from;
push @upgrade_from, sub {
    my $dbfile = shift;

    my $sql = File::Spec->catfile($dist_dir, 'schema', '1.sql');
    DBIx::RunSQL->create(
        dsn => "dbi:SQLite:dbname=$dbfile",
        sql => $sql,
        verbose => 0,
    );
};


upgrades($dbfile);

exit;

sub setup_db {
    my $dbfile = shift;
    
    die "Database file '$dbfile' already exists\n" if -e $dbfile;

    # 0
    my $sql = File::Spec->catfile($dist_dir, 'schema', 'dwimmer.sql');
    DBIx::RunSQL->create(
        dsn => "dbi:SQLite:dbname=$dbfile",
        sql => $sql,
        verbose => 0,
    );

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
    my $time = time;
    my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $dbh->do('INSERT INTO user (name, sha1, email, validation_key, verified, register_ts) VALUES(?, ?, ?, ?, ?, ?)', 
        {}, 
        'admin', sha1_base64($opt{password}), $opt{email}, $validation_key, 1, $time);

    $Dwimmer::Tools::dbfile = $dbfile;

    my $site = 1;
    $dbh->do("INSERT INTO site (name, owner) VALUES ('www', 1)");
    save_page($site, {
            create       => 1,
            editor_title => 'Welcome to your Dwimmer installation',
            editor_body  => '<h1>Dwimmer</h1>',
            author       => 1,
            filename     => '/',
    });


    return if $opt{silent};

    print <<"END_MSG";
Database created.

You can now launch the application and visit the web site
END_MSG

    return;
}

sub upgrades {
    my $dbfile = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

    my ($version) = $dbh->selectrow_array('PRAGMA user_version');
    foreach my $v ($version .. @upgrade_from-1) {
        $upgrade_from[$v]->($dbfile);
    }
}



sub usage {
    pod2usage();
}

=head1 SYNOPSIS

REQUIRED PARAMETERS:

   --email email        of administrator

   --password PASSWORD  of administrator

   --root ROOT          path to the root of the installation

   --dbonly             Create only the database (for development)
   --silent             no success report (for testing)
=cut

