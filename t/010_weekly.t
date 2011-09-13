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

plan(tests => 2);


use Dwimmer::Client::Weekly;
my $user = Dwimmer::Client::Weekly->new( host => $url );
#diag(explain($user->register_email('t1@dwimmer.com')));
is_deeply($user->register_email('t1@dwimmer.com'),
	{
#		dwimmer_version => $Dwimmer::VERSION,
		success => 1,
	}, "submit registration");
#diag(read_file($ENV{DWIMMER_MAIL}));


my $admin = Dwimmer::Client::Weekly->new( host => $url );
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');

