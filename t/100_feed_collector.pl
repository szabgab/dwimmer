use strict;
use warnings;

use Test::More;

use Capture::Tiny qw(capture);
use File::Temp    qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1);

plan tests => 14;

my $store = "$tempdir/data.db";
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl" };
	like $err, qr{--store storage.db}, 'needs --storage';
}

my @sources = (
	{
           'comment' => 'some comment',
           'feed' => 'http://dwimmer.com/atom.xml',
           'id' => 1,
           'status' => 'enabled',
           'title' => 'This is a title',
           'twitter' => 'chirip',
           'url' => 'http://dwimmer.com/'
	},
	{
           'comment' => '',
           'feed' => 'http://szabgab.com/rss.xml',
           'id' => 2,
           'status' => 'enabled',
           'title' => 'My web site',
           'twitter' => 'micro blog',
           'url' => 'http://szabgab.com/'
	},
);


{
	my $infile = save_infile(@{$sources[0]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --add < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my $data = check_dump($out);

	is_deeply $data, [$sources[0]], 'dumped correctly';
	is $err, '', 'no STDERR';
}
{
	my $infile = save_infile(@{$sources[1]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --add < $infile" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[1]], 'dumped correctly';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	like $err, qr{Database .+ already exists}, 'cannot destroy database';
	is $out, '', 'no STDOUT for setup. Really?';
}


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --list dwim" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[0]], 'listed correctly';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --list" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0,1] ], 'listed correctly';
	is $err, '', 'no STDERR';
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


