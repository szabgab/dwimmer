use Test::More;
use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);

plan tests => 13;


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

my $cookie = '';
{
	my $r = dancer_response GET => '/';
	#diag Dumper $r;
	$cookie = $r->header('set-cookie');
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
	my $r = dancer_response GET => '/';
	unlike $r->{content}, qr{/login}, 'no /login';
	like $r->{content}, qr{logged in as.*>admin<}, 'content logged in as admin';
}
{
	my $r = dancer_response GET => '/logout';
	is $r->{status}, 200, '200 ok';
	like $r->{content}, qr{/login}, '/login';
	unlike $r->{content}, qr{admin}, 'no admin';
}



{
	local $ENV{HTTP_REFERER} = 'http://localhost/';
	my $r = dancer_response POST => '/login', {
		params => {username => 'admin', password => $password},
	};
	is $r->{status}, 302, 'redirect' or diag $r->{content};
	is $r->header('location'), 'http://localhost/', 'location';
#	diag Dumper $r;
#	diag $r->header('set-cookie');
#	is $r->header('location'), 'http://localhost/invalid_login';
}

{
	my $r = dancer_response GET => '/list_users';
	like $r->{content}, qr{/show_user\?id=1}, 'admin appears';
}

{
	my $r = dancer_response GET => '/add_user';
	is $r->{status}, 200, '200 ok';
	#diag $r->{content};
}


