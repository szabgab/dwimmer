use strict;
use warnings;

use Test::More;

use Capture::Tiny qw(capture);
use File::Temp    qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1);

plan tests => 3;

my $store = "$tempdir/data.db";
system "$^X script/dwimmer_feed_setup.pl $store";


{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl" };
	like $err, qr{--store storage.db}, 'needs --storage';
}

{
	my @in = ('http://dwimmer.com/', 'http://dwimmer.com/atom.xml', 'This is a title', 'chirip', 'some comment');
	my $infile = "$tempdir/in";
	open my $tmp, '>', $infile or die;
	print $tmp join '', map {"$_\n"} @in;
	close $tmp;
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --add < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my ($dump) = $out =~ /(\$VAR1.*)/s;
	#diag $out;
	#diag $dump;
	our $VAR1;
	eval $dump;
	#diag $@;
	is_deeply $VAR1, {
           'comment' => 'some comment',
           'feed' => 'http://dwimmer.com/atom.xml',
           'id' => 1,
           'status' => 'enabled',
           'title' => 'This is a title',
           'twitter' => 'chirip',
           'url' => 'http://dwimmer.com/'
         }, 'dumped correctly';
}

