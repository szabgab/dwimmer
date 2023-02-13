use 5.012000;
use warnings;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Dwimmer',
	AUTHOR       => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION      => '1.01',
	ABSTRACT     => 'Dwimmer',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {

        'File::Copy::Recursive' => 0,
        'File::Find::Rule'      => 0,
        'File::Spec'            => 0,

	    'autodie'              => 0,
	    'Data::Dumper'         => 0,
	    'DateTime'             => 0,
	    'DBD::SQLite'          => 0,
	    'Encode'               => 0,
	    'Fcntl'                => 0,
	    'File::ShareDir'       => '1.00',
	    'File::Slurp'          => 0,
	    'Getopt::Long'         => 0,
	    'List::Util'           => 0,
	    'LWP::Protocol::https' => 0,        # for https support for the feed reader
	    'JSON'                 => 0,
	    'MIME::Lite'           => 0,
	    'Moose'                => 0,
	    'Pod::Usage'           => 0,
	    'Template'             => 0,
	    'XML::Feed'            => 0,
	    'XML::RSS'             => 0,
	    'XML::Simple'          => 0,
	    'YAML'                 => 0,

        'Test::More'           => 0,
        'Test::Deep'           => 0,
        'Test::WWW::Mechanize' => 0,
        'Test::Differences'    => 0,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Perl-Maven-*' },
);
#homepage 'http://dwimmer.org/';
#bugtracker 'http://github.com/szabgab/dwimmer';
#repository 'http://github.com/szabgab/dwimmer';
#
#install_script 'script/dwimmer_feed_admin.pl';
#install_script 'script/dwimmer_feed_collector.pl';

