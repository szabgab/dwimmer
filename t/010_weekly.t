use strict;
use warnings;

use t::lib::Dwimmer::Test qw(start $admin_mail @users read_file);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan(skip_all => 'Unsupported OS') if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan(tests => 6);


use Dwimmer::Client;

my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');

# create a mailing list
is_deeply($admin->create_list( name => 'Test list' ), {
	listid => 1,
	success => 1,
   }, 'create_list');

# TODO handle duplicate entries
#diag(explain($admin->create_list( name => 'Test list' ) ));
is_deeply($admin->create_list( name => 'Another list' ), {
	listid => 2,
	success => 1,
   }, 'create_list');

is_deeply($admin->fetch_lists, {
	success => 1,
	lists => [
    {
    	listid => 1,
    	name => 'Test list',
    	owner => 1,
    },
    {
    	listid => 2,
    	name => 'Another list',
    	owner => 1,
    },
]}, 'fetch_lists');

# TODO: use sends in subscription, it is saved in database, confirmation e-mail sending
# TODO: user clicks on confirmation

my $user = Dwimmer::Client->new( host => $url );
#diag(explain($user->register_email(email => 't1@dwimmer.com', listid => 1)));
is_deeply($user->register_email(email => 't1@dwimmer.com', listid => 1),
	{
#		dwimmer_version => $Dwimmer::VERSION,
		success => 1,
	}, "submit registration");
my $mail = read_file($ENV{DWIMMER_MAIL});
our $VAR1;
eval $mail;
#diag(explain($VAR1));
is_deeply($VAR1, bless( {
   'Data' => 'Please Confirm',
   'From' => 'gabor@szabgab.com',
   'Subject' => 'Hi',
   'To' => 't1@dwimmer.com'
}, 'MIME::Lite' ), 'expected e-mail structure'); 




