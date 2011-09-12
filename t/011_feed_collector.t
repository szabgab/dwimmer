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


my $admin = Dwimmer::Client->new( host => $url );
is_deeply($admin->login( 'admin', $password ), { 
	success => 1, 
	username => 'admin',
	userid   => 1,
	logged_in => 1,
	}, 'login success');

is_deeply($admin->create_feed_collector('Foo Bar'), {
	success => 1,
}, 'feed_collector_created');

is_deeply($admin->create_feed_collector('Foo Bar'), {
	error => 'feed_collector_exists',
}, 'feed_collector_created already exists');

#diag(explain($admin->get_feed_collectors()));
is_deeply($admin->get_feed_collectors(), {
	result => [
		{
			id => 1,
			name => 'Foo Bar',
		},
	],
	}, 'list feed collectors of current user');


__END__
is_deeply($admin->add_feed(
	title => 'Title of Feed',
	url   => 'http://dwimmer.org/',
	feed  => 'http://dwimmer.org/feed.rss',
	), { success => 1 }, 'adding a feed');

# TODO make sure only the owner can add more feeds


# run feed collection?
#   foreach collector
#      foreach feed
#         process


