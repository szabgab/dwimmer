use Test::More;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);

plan tests => 6;


my $root = dirname dirname abs_path($0);
#diag $root;

#use Dancer qw(config);
#use Dwimmer;
#diag config->{appdir};

my $password = 'dwimmer';

# TODO do this in a temporary directory!
mkdir "$root/db";
unlink "$root/db/dwimmer.db";
system "$^X script/dwimmer_setup.pl --root $root --email test\@dwimmer.org --password $password";


use Dwimmer;
use Dancer::Test;

{
	my $r = dancer_response GET => '/';
	is $r->{status}, 200, '/ ok';
	like $r->{content}, qr{/login}, '/login';
}

{
	# no referer !
	my $r = dancer_response POST => '/login', {
		params => {username => 'admin', password => $password},
	};
	is $r->{status}, 302, 'redirect' or diag $r->{content};
	is $r->header('location'), 'http://localhost/', 'location';
}

{
	local $ENV{HTTP_REFERER} = 'http://localhost/';
	my $r = dancer_response POST => '/login', {
		params => {username => 'admin', password => $password},
	};
	is $r->{status}, 302, 'redirect' or diag $r->{content};
	is $r->header('location'), 'http://localhost/', 'location';
#	is $r->header('location'), 'http://localhost/invalid_login';
}



