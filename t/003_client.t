use strict;
use warnings;

use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan(skip_all => 'Unsupported OS') if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan(tests => 33);


my $w = Test::WWW::Mechanize->new;
$w->get_ok($url);
$w->content_like( qr{Welcome to your Dwimmer installation}, 'content ok' );
$w->get_ok("$url/other");
$w->content_like( qr{Page does not exist}, 'content of missing pages is ok' );

use Dwimmer::Client;
my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', 'xyz' ), { error => 'invalid_password' }, 'invalid_password');
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');
is_deeply($admin->list_users, { users => [
		{ id => 1, name => 'admin', }
	] }, 'list_users');
cmp_deeply($admin->get_user(id => 1), {
	id => 1,
	name => 'admin',
	email => $admin_mail,
	fname => undef,
	lname => undef,
	verified => 1,
	register_ts => re('^\d{10}$'),
	}, 'show user details');

is_deeply($admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'no verify field provided');
$users[0]{verify} = 'abc';
is_deeply($admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'really invalid verify field provided');

$users[0]{verify} = 'verified';
is_deeply($admin->add_user( %{ $users[0] } ), { error => 'email_used' }, 'try to add user with same mail');

$users[0]{email} = 'test2@dwimmer.org';
$users[0]{pw1} = $users[0]{pw2} = $users[0]{password};
is_deeply($admin->add_user( %{ $users[0] } ), { success => 1 }, 'add user with same mail');

is_deeply($admin->list_users, { users => [
		{ id => 1, name => 'admin', },
		{ id => 2, name => $users[0]{uname} },
	] }, 'list_users');

cmp_deeply($admin->get_user(id => 1), {
	id => 1,
	name => 'admin',
	email => $admin_mail,
	fname => undef,
	lname => undef,
	verified => 1,
	register_ts => re('^\d{10}$'),
	}, 'show user details');
cmp_deeply($admin->get_user(id => 2), {
	id => 2,
	name => $users[0]{uname},
	email => $users[0]{email},
	fname => undef,
	lname => undef,
	verified => 1,
	register_ts => re('^\d{10}$'),
	}, 'show user details');

cmp_deeply($admin->get_pages, { rows => [
	{
		id       => 1,
		filename => '/',
		title    => 'Welcome to your Dwimmer installation',
	},
	]}, 'get pages');


is_deeply($admin->get_page('/'), {
#	dwimmer_version => $Dwimmer::Client::VERSION,
#	userid => 1,
#	logged_in => 1,
#	username => 'admin',
	page => {
		body     => '<h1>Dwimmer</h1>',
		title    => 'Welcome to your Dwimmer installation',
		filename => '/',
		author   => 'admin',
	},
	}, 'page data');

is_deeply($admin->save_page(
		body     => 'New text [link] here',
		title    => 'New title',
		filename => '/',
		), { success => 1 }, 'save_page');
is_deeply($admin->get_page('/'), {
#	dwimmer_version => $Dwimmer::Client::VERSION,
#	userid => 1,
#	logged_in => 1,
#	username => 'admin',
	page => {
		body     => 'New text [link] here',
		title    => 'New title',
		filename => '/',
		author   => 'admin',
	},
	}, 'page data after save');

$w->get_ok($url);
$w->content_like( qr{New text <a href="link">link</a> here}, 'link markup works' );

# for creating new page we require a special field to reduce the risk of
# accidental page creation
is_deeply($admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
		), { error => 'page_does_not_exist' }, 'save_page');
cmp_deeply($admin->get_pages, { rows => [
	{
		id       => 1,
		filename => '/',
		title    => 'New title',
	},
	]}, 'get pages');
is_deeply($admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
		create   => 1,
		), { success => 1 }, 'create new page');
cmp_deeply($admin->get_pages, { rows => [
	{
		id       => 1,
		filename => '/',
		title    => 'New title',
	},
	{
		id       => 2,
		filename => '/xyz',
		title    => 'New title of xyz',
	},
	]}, 'get pages');





my $user = Dwimmer::Client->new( host => $url );
is_deeply($user->list_users, { 
	dwimmer_version => $Dwimmer::Client::VERSION, 
	error => 'not_logged_in',
	}, 'to list_users page');
is_deeply($user->login($users[0]{uname}, $users[0]{password}), { 
	success => 1,
	username => $users[0]{uname},
	userid   => 2,
	logged_in => 1,
	}, 'user logged in');
is_deeply($user->get_session, { logged_in => 1, username => $users[0]{uname}, userid => 2 }, 'not logged in');
cmp_deeply($user->get_user(id => 2), {
	id => 2,
	name => $users[0]{uname},
	email => $users[0]{email},
	fname => undef,
	lname => undef,
	verified => 1,
	register_ts => re('^\d{10}$'),
	}, 'show user own details');
# TODO should this user be able to see the list of user?
# TODO this user should NOT be able to add new users

is_deeply($user->logout, { success => 1 }, 'logout');
is_deeply($user->get_session, {
	logged_in => 0, 
#	dwimmer_version => $Dwimmer::Client::VERSION,
	}, 'get_session');
#diag(explain($user->get_user(id => 2)));
is_deeply($user->get_user(id => 2), {
	dwimmer_version => $Dwimmer::Client::VERSION, 
	error => 'not_logged_in',
}, 'cannot get user data afer logout');

my $guest = Dwimmer::Client->new( host => $url );
is_deeply($guest->list_users, { 
	dwimmer_version => $Dwimmer::Client::VERSION, 
	error => 'not_logged_in',
	}, 'to list_users page');

#diag(read_file($ENV{DWIMMER_MAIL}));

# TODO configure smtp server for email
