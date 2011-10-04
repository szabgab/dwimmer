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
my $list_name = 'Test list';
my $from_address = 'admin1@dwimmer.org';
is_deeply_full($admin->create_list( name => $list_name, from_address => $from_address ), {
	listid => 1,
	success => 1,
   }, 'create_list');

# TODO handle duplicate entries
#diag(explain($admin->create_list( name => $list_name ) ));
is_deeply_full($admin->create_list( name => 'Another list', from_address => 'other@dwimmer.org' ), {
	listid => 2,
	success => 1,
   }, 'create_list');

is_deeply_full($admin->fetch_lists, {
	success => 1,
	lists => [
    {
    	listid => 1,
    	name => $list_name,
    	owner => 1,
    },
    {
    	listid => 2,
    	name => 'Another list',
    	owner => 1,
    },
]}, 'fetch_lists');

# TODO: user sends in subscription via HTTP
# it is saved in database, confirmation e-mail sending
# TODO: user clicks on confirmation
# set the From e-mail

my $user = Dwimmer::Client->new( host => $url );
#diag(explain($user->register_email(email => 't1@dwimmer.org', listid => 1)));
is_deeply($user->register_email(email => 't1@dwimmer.org', listid => 1),
	{
		success => 1,
	}, "submit registration");
my $mail = read_file($ENV{DWIMMER_MAIL});
our $VAR1;
eval $mail;
#diag(explain($VAR1));
is_deeply($VAR1, bless( {
   'Data' => 'Please Confirm',
   'From' => $from_address,
   'Subject' => "$list_name registration",
   'To' => 't1@dwimmer.org'
}, 'MIME::Lite' ), 'expected e-mail structure'); 



sub is_deeply_full {
	my ($result, $expected, $title) = @_;
	my $ok = is_deeply($result, $expected, $title);
	diag(explain($result)) if not $ok;
	return $ok;
}
