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

plan(tests => 4);


use Dwimmer::Client;
my $user = Dwimmer::Client->new( host => $url );
#$user->register

my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');

# just to make sure we don't have the same default page
# is_deeply($admin->save_page(
		# body     => 'New text [link] here',
		# title    => 'New main title',
		# filename => '/',
		# ), { success => 1 }, 'save_page');

is_deeply($admin->create_site( name => 'foobar' ), {
	success => 1, 
}, 'create_site foobar');

# fetch main page of new site
#$admin->switch_host( fake => 'foobar' );
#$admin->get_page('/');

my $w = Test::WWW::Mechanize->new;
$w->get_ok("$url/?_dwimmer=foobar"); # faking hostname
$w->content_like( qr{Welcome to foobar}, 'content ok' ) or diag($w->content);

