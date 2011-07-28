use strict;
use warnings;

use t::lib::Dwimmer::Test;

$ENV{DWIMMER_TEST} = 1;
start();

# TODO set my own port?
# TODO eliminate the logging to the console?

eval "use Test::More";
require Test::WWW::Mechanize;

my $url = "http://localhost:3000/";

plan(tests => 1);

#diag("xx");
my $w = Test::WWW::Mechanize->new;
#diag("yy");
$w->get_ok($url);
#diag("cc");

stop();
