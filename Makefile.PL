use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dwimmer',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/Dwimmer.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer'              => 1.3060,
        'Data::Dumper'        => 0,
        'DBIx::Class'         => 0,
        'DBIx::Class::Schema' => 0,
        'DBIx::RunSQL'        => 0,
        'Email::Valid'        => 0,
        'File::Spec'          => 0,
        'Getopt::Long'        => 0,
        'MIME::Lite'          => 0,
        'Pod::Usage'          => 0,
        'String::Random'      => 0,
        'Template'            => 0,
        'Test::More'          => 0,
        'YAML'                => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dwimmer-*' },
);
