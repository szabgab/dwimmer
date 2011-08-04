use strict;
use warnings;

use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);

my $password = 'dwimmer';

start($password);


eval "use Test::More";
require Test::WWW::Mechanize;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan(tests => 5);

use Dwimmer::Client;
my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', 'xyz' ), { error => 'invalid_password' }, 'invalid_password');
is_deeply($admin->login( 'admin', $password ), { success => 1 }, 'login success');
is_deeply($admin->list_users, { users => [
		{ id => 1, name => 'admin', }
	] }, 'list_users');
is_deeply($admin->get_user(id => 1), {
	id => 1,
	name => 'admin',
	email => $admin_mail,
	}, 'show user details');

my $guest = Dwimmer::Client->new( host => $url );
is_deeply($guest->list_users, { 
	dwimmer_version => $Dwimmer::Client::VERSION, 
	error => 'not_logged_in',
	}, 'to list_users page');

