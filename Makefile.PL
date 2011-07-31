use 5.008005;
use strict;
use warnings;
use inc::Module::Install 1.00;

# Configure-time dependencies MUST be done first.
# This version ensures that we have a new MakeMaker that
# WON'T load modules to determine the version.
# This _SHOULD_ theoretically make the "require Test::NoWarnings".
# stuff above here no longer needed.
configure_requires 'ExtUtils::MakeMaker' => '6.52';


name     'Dwimmer';
license  'perl';
author   'Gabor Szabo <szabgab@dwimmer.org>';
all_from 'lib/Dwimmer.pm';

requires 'perl' => '5.008005';

my %prereq = (
        'autodie'              => 0,
        'Dancer'               => 1.3060,
        'Data::Dumper'         => 0,
        'DBIx::Class'          => 0,
        'DBIx::Class::Schema'  => 0,
        'DBIx::RunSQL'         => 0,
        'Email::Valid'         => 0,
        'File::ShareDir'       => '1.00',
        'File::Slurp'          => 0,
        'File::Spec'           => 0,
        'File::Copy::Recursive' => 0,
        'Getopt::Long'         => 0,
        'MIME::Lite'           => 0,
        'Pod::Usage'           => 0,
        'String::Random'       => 0,
        'Template'             => 0,
        'YAML'                 => 0,
);
if ($^O =~ /win32/i) {
    $prereq{'Win32::Process'} = 0;
}

foreach my $module (keys %prereq) {
        requires $module => $prereq{$module};
}

test_requires        'Test::More'            => 0;
test_requires        'Test::WWW::Mechanize'  => 0;


homepage 'http://dwimmer.org/';
bugtracker 'http://github.com/szabgab/dwimmer';
repository 'http://github.com/szabgab/dwimmer';

install_script 'script/dwimmer_setup.pl';

# Copy files to share before packaging it
require File::Copy::Recursive;
require File::Spec;
foreach my $dir (qw(bin views schema public)) {
        File::Copy::Recursive::dircopy( $dir, File::Spec->catdir('share', $dir) );
}

install_share;


WriteAll;
