use strict;
use warnings;

use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use JSON qw(from_json);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan( skip_all => 'Unsupported OS' ) if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan( tests => 49 );

my @pages = (
	{},
	{},
	{   body     => 'File with space and dot',
		title    => 'dotspace',
		filename => '/space and.dot and $@% too',
	}
);
my @exp_pages =
	map { { id => $_ + 1, filename => $pages[$_]->{filename}, title => $pages[$_]->{title}, } } 0 .. @pages - 1;
my @links = map { $_->{filename} ? substr( $_->{filename}, 1 ) : '' } @pages;
my @exp_links = map { quotemeta($_) } @links;

my $w = Test::WWW::Mechanize->new;
$w->get_ok($url);
$w->content_like( qr{Welcome to your Dwimmer installation}, 'content ok' );
$w->get_ok("$url/other");
$w->content_like( qr{Page does not exist}, 'content of missing pages is ok' );
$w->content_unlike( qr{Would you like to create it}, 'no creation offer' );

my $u = Test::WWW::Mechanize->new;
$u->get_ok($url);
$u->post_ok(
	"$url/_dwimmer/login.json",
	{   username => 'admin',
		password => $password,
	}
);
is_deeply(
	from_json( $u->content ),
	{   "success"   => 1,
		"userid"    => 1,
		"logged_in" => 1,
		"username"  => "admin",
	},
	'logged in'
);
$u->get_ok("$url/other");
$u->content_like( qr{Page does not exist}, 'content of missing pages is ok' );
$u->content_like( qr{Would you like to <a class="create_page" href="">create</a> it}, 'creation offer' );


use Dwimmer::Client;
my $admin = Dwimmer::Client->new( host => $url );
is_deeply(
	$admin->login( username => 'admin', password => 'xyz' ), { error => 'invalid_password' },
	'invalid_password'
);
is_deeply(
	$admin->login( username => 'admin', password => $password ),
	{   success   => 1,
		username  => 'admin',
		userid    => 1,
		logged_in => 1,
	},
	'login success'
);
is_deeply(
	$admin->list_users, { users => [
			{ id => 1, name => 'admin', }
			] }, 'list_users'
);
cmp_deeply(
	$admin->get_user( id => 1 ),
	{   id          => 1,
		name        => 'admin',
		email       => $admin_mail,
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);

is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'no verify field provided' );
$users[0]{verify} = 'abc';
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'invalid_verify' }, 'really invalid verify field provided' );

$users[0]{verify} = 'verified';
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'email_used' }, 'try to add user with same mail' );

$users[0]{email} = ucfirst $users[0]{email};
is_deeply(
	$admin->add_user( %{ $users[0] } ), { error => 'email_used' },
	'try to add user with same mail after ucfirst'
);

$users[0]{email} = uc $users[0]{email};
is_deeply( $admin->add_user( %{ $users[0] } ), { error => 'email_used' }, 'try to add user with same mail after uc' );

$users[0]{email} = 'test2@dwimmer.org';
$users[0]{pw1} = $users[0]{pw2} = $users[0]{password};
is_deeply( $admin->add_user( %{ $users[0] } ), { success => 1 }, 'add user with same mail' );

is_deeply(
	$admin->list_users,
	{   users => [
			{ id => 1, name => 'admin', },
			{ id => 2, name => $users[0]{uname} },
		]
	},
	'list_users'
);

cmp_deeply(
	$admin->get_user( id => 1 ),
	{   id          => 1,
		name        => 'admin',
		email       => $admin_mail,
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);
cmp_deeply(
	$admin->get_user( id => 2 ),
	{   id          => 2,
		name        => $users[0]{uname},
		email       => $users[0]{email},
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user details'
);

cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'Welcome to your Dwimmer installation',
			},
		]
	},
	'get pages'
);


is_deeply(
	$admin->page( filename => '/' ),
	{

		#	dwimmer_version => $Dwimmer::Client::VERSION,
		#	userid => 1,
		#	logged_in => 1,
		#	username => 'admin',
		page => {
			body     => '<h1>Dwimmer</h1>',
			title    => 'Welcome to your Dwimmer installation',
			filename => '/',
			author   => 'admin',
			revision => 1,
		},
	},
	'page data'
);

is_deeply(
	$admin->save_page(
		body     => "New text [link] here and [$links[2]] here",
		title    => 'New main title',
		filename => '/',
	),
	{ success => 1 },
	'save_page'
);
is_deeply(
	$admin->page( filename => '/' ),
	{

		#	dwimmer_version => $Dwimmer::Client::VERSION,
		#	userid => 1,
		#	logged_in => 1,
		#	username => 'admin',
		page => {
			body     => "New text [link] here and [$links[2]] here",
			title    => 'New main title',
			filename => '/',
			author   => 'admin',
			revision => 2,
		},
	},
	'page data after save'
);

$w->get_ok($url);

$w->content_like(
	qr{New text <a href="link">link</a> here and <a href="$exp_links[2]">$exp_links[2]</a> here},
	'link markup works'
);

# for creating new page we require a special field to reduce the risk of
# accidental page creation
is_deeply(
	$admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
	),
	{ error => 'page_does_not_exist' },
	'save_page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
		]
	},
	'get pages'
);
is_deeply(
	$admin->save_page(
		body     => 'New text',
		title    => 'New title of xyz',
		filename => '/xyz',
		create   => 1,
	),
	{ success => 1 },
	'create new page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
			{   id       => 2,
				filename => '/xyz',
				title    => 'New title of xyz',
			},
		]
	},
	'get pages'
);

is_deeply(
	$admin->save_page(
		%{ $pages[2] },
		create => 1,
	),
	{ success => 1 },
	'create new page'
);
cmp_deeply(
	$admin->get_pages,
	{   rows => [
			{   id       => 1,
				filename => '/',
				title    => 'New main title',
			},
			{   id       => 2,
				filename => '/xyz',
				title    => 'New title of xyz',
			},
			$exp_pages[2],
		]
	},
	'get pages'
);
$w->get_ok("$url$pages[2]{filename}");
$w->content_like(qr{$pages[2]{body}});


my $user = Dwimmer::Client->new( host => $url );
is_deeply(
	$user->list_users,
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'to list_users page'
);
is_deeply(
	$user->login( username => $users[0]{uname}, password => $users[0]{password} ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in'
);
is_deeply( $user->session, { logged_in => 1, username => $users[0]{uname}, userid => 2 }, 'not logged in' );
cmp_deeply(
	$user->get_user( id => 2 ),
	{   id          => 2,
		name        => $users[0]{uname},
		email       => $users[0]{email},
		fname       => undef,
		lname       => undef,
		verified    => 1,
		register_ts => re('^\d{10}$'),
	},
	'show user own details'
);

# TODO should this user be able to see the list of user?
# TODO this user should NOT be able to add new users

my $pw1 = 'qwerty';
is_deeply(
	$user->change_password( new_password => $pw1, old_password => $users[0]{password} ),
	{ success => 1 }, 'password changed'
);

is_deeply( $user->logout, { success => 1 }, 'logout' );
is_deeply(
	$user->session,
	{   logged_in => 0,

		#	dwimmer_version => $Dwimmer::Client::VERSION,
	},
	'session'
);

#diag(explain($user->get_user(id => 2)));
is_deeply(
	$user->get_user( id => 2 ),
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'cannot get user data afer logout'
);

my $guest = Dwimmer::Client->new( host => $url );
is_deeply(
	$guest->list_users,
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'to list_users page'
);

#diag(read_file($ENV{DWIMMER_MAIL}));

# TODO configure smtp server for email

my $failed_pw = 'uiop';
is_deeply(
	$user->change_password( new_password => $failed_pw, old_password => $pw1 ),
	{   dwimmer_version => $Dwimmer::Client::VERSION,
		error           => 'not_logged_in',
	},
	'need to login to change password'
);

#diag(explain(	$user->login( username => $users[0]{uname}, password => $pw1 ) ));

is_deeply(
	$user->login( username => $users[0]{uname}, password => $pw1 ),
	{   success   => 1,
		username  => $users[0]{uname},
		userid    => 2,
		logged_in => 1,
	},
	'user logged in with new password'
);

