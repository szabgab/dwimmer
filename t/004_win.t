use strict;
use warnings;

use t::lib::Dwimmer::Test;

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
#use File::Slurp qw(read_file);

my $password = 'dwimmer';

start($password);


eval "use Test::More";
require Test::WWW::Mechanize;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan(tests => 31);

use Dwimmer::Client;
my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', 'xyz' ), { error => 'invalid_password' }, 'invalid_password');
is_deeply($admin->login( 'admin', $password ), { success => 1 }, 'login success');

my $guest = Dwimmer::Client->new( host => $url );
is_deeply($guest->list_users, { 
	dwimmer_version => $Dwimmer::Client::VERSION, 
	error => 'not_logged_in',
	}, 'to list_users page');

my $w = Test::WWW::Mechanize->new;
$w->get_ok($url);

$w->content_like(qr{/login}, '/login');
$w->content_unlike(qr{logged in}, 'not logged in');

$w->submit_form_ok( {
	form_name => '',
	fields => {
		username => 'admin', 
		password => $password,
	},
	}, 'submit login');
	
is($w->status, 200, 'status 200');
#diag($w->content);
$w->content_like(qr{logged in as.*>admin<}, 'content logged in as admin');


$w->follow_link_ok({ url => '/_dwimmer/manage'}, 'to manage page');
$w->follow_link_ok({ url => '/_dwimmer/list_users'}, 'to list_users page');
$w->content_like(qr{/show_user\?id=1}, 'admin appears');

$w->follow_link_ok({ url => '/_dwimmer/manage'}, 'to manage page');
$w->follow_link_ok({ url => '/_dwimmer/add_user'}, 'to add_user page');

my @users = (
	{
		uname    => 'tester',
		fname    => 'foo',
		lname    => 'bar',
		email    => 'test@dwimmer.org',
		password => 'dwimmer',
	},
);
$w->submit_form_ok( {
	form_name => '',
	fields => $users[0],
}, 'add user');
$w->content_like( qr{This email was already used}, 'email error' );

$w->back;

$users[0]{email} = 'test2@dwimmer.org';
$users[0]{pw1} = $users[0]{pw2} = $users[0]{password};
$users[0]{verify} = 'verified';
#$w->set_visible( [ radio => 'verified' ] );
$w->submit_form_ok( {
	form_name => '',
	fields => $users[0],
}, 'add user');
$w->content_like( qr{user added} );
$w->follow_link_ok({ url => '/_dwimmer/manage'}, 'to manage page');
$w->follow_link_ok({ url => '/_dwimmer/list_users'}, 'to list_users page');
$w->content_like(qr{/_dwimmer/show_user\?id=1">admin}, 'admin appears');
$w->content_like(qr{/_dwimmer/show_user\?id=2">$users[0]{uname}}, "$users[0]{uname} appears");
#diag($w->content);


#diag(read_file($ENV{DWIMMER_MAIL}));
my $u = Test::WWW::Mechanize->new;
$u->get_ok("$url/_dwimmer/manage");
#diag($u->content);
$u->content_like( qr{have to be logged in}, 'not logged in');
$u->get_ok("$url/_dwimmer/manage");
$u->content_like( qr{have to be logged in}, 'not logged in');

$u->get_ok($url);
$u->submit_form_ok( {
	form_name => '',
	fields => {
		username => $users[0]{uname},
		password => $users[0]{password},
	},
	}, "submit login for $users[0]{uname}");
$u->content_like(qr{logged in as.*>$users[0]{uname}<}, "content logged in as $users[0]{uname}");
#diag($u->content);

# TODO configure SMTP server for e-mail


$w->follow_link_ok({text_regex => qr{logout}}, 'logout');
$w->content_unlike(qr{logged in}, 'not logged in');

