use strict;
use warnings;

use t::lib::Dwimmer::Test;

$ENV{DWIMMER_TEST} = 1;
$ENV{DWIMMER_PORT} = 3001;

start();

eval "use Test::More";
require Test::WWW::Mechanize;

my $url = "http://localhost:$ENV{DWIMMER_PORT}/";

plan(tests => 1);

#diag("xx");
my $w = Test::WWW::Mechanize->new;
#diag("yy");
$w->get_ok($url);
#diag("cc");

stop();
