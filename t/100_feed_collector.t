use strict;
use warnings;

use Test::More;
use Test::Deep;

use Capture::Tiny qw(capture);
use Data::Dumper  qw(Dumper);
use DateTime;
use File::Copy    qw(copy);
use File::Temp    qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1);
my $html_dir = "$tempdir/html";
mkdir $html_dir or die;
my $site = 'drinks';
my $site2 = 'food';
my @sources = (
	{
           'comment' => 'some comment',
           'feed' => "file://$tempdir/atom.xml",
           'id' => 1,
           'status' => 'enabled',
           'title' => 'This is a title',
           'twitter' => 'chirip',
           'url' => 'http://beer.com/',
           'site_id' => 1,
	},
	{
           'comment' => '',
           'feed' => "file://$tempdir/rss.xml",
           'id' => 2,
           'status' => 'enabled',
           'title' => 'My web site',
           'twitter' => 'micro blog',
           'url' => 'http://vodka.com/',
           'site_id' => 1,
	},
);
my @sources2 = (
	{
           'comment' => 'Food store',
           'feed' => "file://$tempdir/burger.xml",
           'id' => 3,
           'status' => 'enabled',
           'title' => 'This is a title of the Brugers',
           'twitter' => 'burger_land',
           'url' => 'http://burger.com/',
           'site_id' => 2,
	},
);


plan tests => 65;

my $store = "$tempdir/data.db";
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl" };
	like $err, qr{--store storage.db}, 'dwimmer_feed_admin.pl requires the --store option';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store" };
	like $err, qr{does NOT exist}, 'first dwimmer_feed_admin.pl needs to be called with --setup';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --addsite $site" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}

# TODO list sites

{
	my $infile = save_infile(@{$sources[0]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --site $site --add < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my $data = check_dump($out);

	is_deeply $data, [$sources[0]], 'dumped correctly after adding feed';
	is $err, '', 'no STDERR';
}

{
	my $infile = save_infile(@{$sources[1]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --site $site --add < $infile" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[1]], 'dumped correctly after adding second feed';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --addsite $site2" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}

# list sources
# TODO list sites


{
	my $infile = save_infile(@{$sources2[0]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --add --site $site2 < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my $data = check_dump($out);

	is_deeply $data, [$sources2[0]], 'dumped correctly after adding feed';
	is $err, '', 'no STDERR';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	like $err, qr{Database .+ already exists}, 'cannot destroy database';
	is $out, '', 'no STDOUT for setup. Really?';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource beer" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[0]], 'listed correctly';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0,1], $sources2[0] ], 'listed correctly';
	is $err, '', 'no STDERR';
}

# disable
my $disabled = clone($sources[0]);
$disabled->{status} = 'disabled';
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --disable 1" };
	my $data = check_dump($out);
	is_deeply $data, [ $sources[0], $disabled ], '--disable';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ $disabled, $sources[1], $sources2[0] ], 'listed correctly after disable';
	is $err, '', 'no STDERR';
}

# enable
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --enable 1" };
	my $data = check_dump($out);
	is_deeply $data, [ $disabled, $sources[0] ], '--enable';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0, 1], $sources2[0] ], 'listed correctly after enable';
	is $err, '', 'no STDERR';
}

# config
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig" };
	my $data = check_dump($out);
	is_deeply $data, [[]], 'no config';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config from foo\@bar.com --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config another option --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [[{
		key => 'from',
		value => 'foo@bar.com',
		site_id => 1,
		},
		{
			key => 'another',
			value => 'option',
			site_id => 1,
		},
		]], 'config' or diag $out;
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --unconfig another --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [[{
		key => 'from',
		value => 'foo@bar.com',
		site_id => 1,
		},
		]], 'config';
	is $err, '', 'no STDERR';
}


{
	my ($out, $err) = capture { system qq{$^X script/dwimmer_feed_admin.pl --store $store --config html_dir "$html_dir" --site $site} };
	#diag $out;
	#my $data = check_dump($out);
	#is_deeply $data, [[]], 'no config';
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}


# disable for now so we only test the rss
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --disable 1" };
	copy 't/files/rss.xml', "$tempdir/rss.xml";
	copy 't/files/burger.xml', "$tempdir/burger.xml";
}

# running the collector, I'd think it should give some kind of an error message if it cannot find feed
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store" };
	is $out, '', 'no STDOUT';
	like $err, qr{Usage: }, 'Usage on STDERR';
	#diag $err;
}
{
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listqueue mail" };
		is $err, '';
		my $data = check_dump($out);
		is_deeply $data, [[]];
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listentries" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
             {
               'author' => 'szabgab',
               'link' => 'http://perl6maven.com/parsing-command-line-arguments-perl6',
               'remote_id' => undef,
               'source_id' => 3,
               'content' => '',
               'tags' => '',
               'summary' => re('Perl 6 application'),
               'issued' => '2012-09-14 10:52:03',
               'id' => 2,
               'title' => 'Parsing command line arguments in Perl 6'
             },
			{
		       'author' => 'Gabor Szabo',
		       'content' => re('^\s*Description\s*$'),
		       'id' => 1,
		       'issued' => '2012-03-28 10:57:35',
		       'link' => 'http://szabgab.com/first.html',
		       'remote_id' => undef,
		       'source_id' => 2,
		       'summary' => '',
		       'tags' => '',
		       'title' => 'First title'
		     }]];
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --html" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}
}


{
	open my $fh, '<', 't/files/rss2.xml' or die;
	my $content = do { local $/ = undef; <$fh> };
	my $dt = DateTime->now;;
	$content =~ s/DATE/$dt/;
	open my $out, '>', "$tempdir/rss.xml" or die;
	print $out $content;
	close $fh;
	close $out;

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listqueue mail" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
			{
				'remote_id' => undef,
				'link' => 'http://szabgab.com/second.html',
				'entry' => 3,
				'source_id' => 2,
				'site_id' => 1,
				'content' => re('^\s*Placeholder for some texts\s*'),
				'channel' => 'mail',
				'author' => 'Foo',
				'tags' => '',
				'summary' => '',
				'issued' => re('^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$'),
				'id' => 3,
				'title' => 'Second title'
			}
		]];
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listentries" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
			{
				'author' => 'Foo',
				'content' => re('^\s*Placeholder for some texts\s*$'),
				'id' => 3,
				'issued' => re('^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$'),
				'link' => 'http://szabgab.com/second.html',
				'remote_id' => undef,
				'source_id' => 2,
				'summary' => '',
				'tags' => '',
				'title' => 'Second title'
			},
             {
               'author' => 'szabgab',
               'link' => 'http://perl6maven.com/parsing-command-line-arguments-perl6',
               'remote_id' => undef,
               'source_id' => 3,
               'content' => '',
               'tags' => '',
               'summary' => re('Perl 6 application'),
               'issued' => '2012-09-14 10:52:03',
               'id' => 2,
               'title' => 'Parsing command line arguments in Perl 6'
             },
			{
				'author' => 'Gabor Szabo',
				'content' => re('^\s*Description\s*$'),
				'id' => 1,
				'issued' => '2012-03-28 10:57:35',
				'link' => 'http://szabgab.com/first.html',
				'remote_id' => undef,
				'source_id' => 2,
				'summary' => '',
				'tags' => '',
				'title' => 'First title'
			}
	]];
	}
}

{
#	open my $atom, '>', "$tempdir/atom.xml" or die;
#	print $atom 'Garbage';
#	close $atom;
#	open my $rss, '>', "$tempdir/rss.xml" or die;
#	print $rss 'rss Garbage';
#	close $rss;
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect" };
# TODO better testing the log output? do we need that?
	like $out, qr{Elapsed time: [01]\s*$}, 'STDOUT is only elapsed time';
	is $err, '', 'no STDERR';
}


exit;
############################################################################

sub clone {
	my $old = shift;
	my $dump = Dumper $old;
	$dump =~ s/\$VAR1\s+=//;
	my $var = eval $dump;
	die $@ if $@;
	return $var;
}


sub check_dump {
	my ($out) = @_;

	my @parts = split /\$VAR1\s+=\s*/, $out;
	shift @parts;

	my @data;
	foreach my $p (@parts) {
		my $v = eval $p;
		die $@ if $@;
		push @data, $v;
	}
	return \@data;
}

sub save_infile {
	my @in = @_;

	my $infile = "$tempdir/in";
	open my $tmp, '>', $infile or die;
	print $tmp join '', map {"$_\n"} @in;
	close $tmp;
	return $infile;
}


