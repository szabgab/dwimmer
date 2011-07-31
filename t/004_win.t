use strict;
use warnings;

use t::lib::Dwimmer::Test;

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use File::Slurp qw(read_file);
use File::Spec;
use File::Temp qw(tempdir);

my $dir = tempdir( CLEANUP => 1 );

$ENV{DWIMMER_TEST} = 1;
$ENV{DWIMMER_PORT} = 3001;
$ENV{DWIMMER_MAIL} = File::Spec->catfile($dir, 'mail.txt');

my $password = 'dwimmer';
my $root = File::Spec->catdir($dir, 'dwimmer');
system "$^X script/dwimmer_setup.pl --root $root --email test\@dwimmer.org --password $password";

start($root);


eval "use Test::More";
require Test::WWW::Mechanize;

my $url = "http://localhost:$ENV{DWIMMER_PORT}/";

plan(tests => 17);

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


$w->follow_link_ok({ url => '/manage'}, 'to manage page');
$w->follow_link_ok({ url => '/list_users'}, 'to list_users page');
$w->content_like(qr{/show_user\?id=1}, 'admin appears');

$w->follow_link_ok({ url => '/manage'}, 'to manage page');
$w->follow_link_ok({ url => '/add_user'}, 'to add_user page');

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
$w->submit_form_ok( {
	form_name => '',
	fields => $users[0],
}, 'add user');
$w->content_like( qr{user added} );

#diag(read_file($ENV{DWIMMER_MAIL}));


$w->follow_link_ok({text_regex => qr{logout}}, 'logout');
$w->content_unlike(qr{logged in}, 'not logged in');


stop();

