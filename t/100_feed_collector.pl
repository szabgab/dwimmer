use strict;
use warnings;

use Test::More;

use Capture::Tiny qw(capture);
use Data::Dumper  qw(Dumper);
use File::Temp    qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1);

plan tests => 28;

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
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --list" };
	my $data = check_dump($out);
	is_deeply $data, [ $disabled, $sources[1] ], 'listed correctly after disable';
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
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --list" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0, 1] ], 'listed correctly after enable';
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
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config from foo\@bar.com" };
	#diag $out;
	#my $data = check_dump($out);
	#is_deeply $data, [[]], 'no config';
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig" };
	my $data = check_dump($out);
	is_deeply $data, [[{
		key => 'from',
		value => 'foo@bar.com',
		},
		]], 'no config';
	is $err, '', 'no STDERR';
}


exit;

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


