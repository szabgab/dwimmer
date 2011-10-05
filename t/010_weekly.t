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

plan(tests => 9);


use Dwimmer::Client;

my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');

# create a mailing list
my $list_title = 'Test list';
my $list_name  = 'test_list';
my $from_address = 'admin1@dwimmer.org';
my $validate_template = <<'END_VALIDATE';
Opening: I am ready to send you updates.

-----------------------------------------------------------
CONFIRM BY VISITING THE LINK BELOW:

<% url %>

Click the link above to give me permission to send you
information.  It's fast and easy!  If you cannot click the
full URL above, please copy and paste it into your web
browser.

-----------------------------------------------------------
If you do not want to confirm, simply ignore this message.

Thank You Again!

END_VALIDATE

my $confirm_template = <<'END_CONFIRM';
END_CONFIRM

is_deeply_full($admin->create_list( 
		title => $list_title,
		name  => $list_name,
		from_address => $from_address,
		validate_template => $validate_template,
		confirm_template => $confirm_template,
		response_page => '/response_page',
		validation_page => '/valiadate_page',
		valiadtion_response_page => '/final_page',
		), {
	listid => 1,
	success => 1,
   }, 'create_list');

# TODO: check identical names
is_deeply_full($admin->create_list( 
		title => 'Another list',
		name  => 'another_list',
		from_address => 'other@dwimmer.org',
		validate_template => 'validate <% url %>',
		confirm_template => '<% url %>',
		response_page => '/response_page',
		validation_page => '/valiadate_page',
		valiadtion_response_page => '/final_page',
		), {
	listid => 2,
	success => 1,
   }, 'create_list');

is_deeply_full($admin->fetch_lists, {
	success => 1,
	lists => [
    {
    	listid => 1,
    	title => $list_title,
    	name  => $list_name,
    	owner => 1,
    },
    {
    	listid => 2,
    	title => 'Another list',
    	name  => 'another_list',
    	owner => 1,
    },
]}, 'fetch_lists');

# TODO: user sends in subscription via HTTP
# it is saved in database, confirmation e-mail sending
# TODO: user clicks on confirmation
# set the From e-mail

my $user = Dwimmer::Client->new( host => $url );
#diag(explain($user->register_email(email => 't1@dwimmer.org', listid => 1)));
is_deeply_full($user->register_email(email => 't1@dwimmer.org', listid => 1),
	{
		success => 1,
	}, "submit registration");
our $VAR1;

my $validate_mail = read_file($ENV{DWIMMER_MAIL});
eval $validate_mail;
#diag(explain($VAR1));
# my $validate = $validate_template;
my $found_code = '';
if ($VAR1->{Data} =~ s{http://localhost:3001/validate_email\?listid=1&email=t1\@dwimmer\.org&code=(\w+)}{<% url %>}) {
	$found_code = $1;
}

is_deeply_full($VAR1, bless( {
   'Data' => $validate_template,
   'From' => $from_address,
   'Subject' => "$list_title registration - email validation",
   'To' => 't1@dwimmer.org'
}, 'MIME::Lite' ), 'expected e-mail structure'); 
$VAR1 = undef;

diag("code='$found_code'");
is_deeply_full($user->validate_email(listid => 1, email => 't1@dwimmer.org', code => $found_code), {
	success => 1,
	}, 'validate_email');
my $confirm_mail = read_file($ENV{DWIMMER_MAIL});
eval $confirm_mail;
#diag(explain($VAR1));
is_deeply_full($VAR1, bless( {
   'Data' => $confirm_template,
   'From' => $from_address,
   'Subject' => "$list_title - Thank you for subscribing",
   'To' => 't1@dwimmer.org'
}, 'MIME::Lite' ), 'expected e-mail structure'); 

# TODO:
# admin should create a page with the form
# designate a page to be the response page and create it (the same for the validation page)


my $web_user = Test::WWW::Mechanize->new;
$web_user->get_ok($url);
#$web_user->submit_form_ok( {
#}, 'submit regisration');



sub is_deeply_full {
	my ($result, $expected, $title) = @_;
	my $ok = is_deeply($result, $expected, $title);
	diag(explain($result)) if not $ok;
	return $ok;
}

# TODO validation mail: subject, template
# TODO validation web page, error messages
# TODO confirm mail: subject, template

