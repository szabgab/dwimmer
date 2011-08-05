use strict;
use warnings;

use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
#use File::Slurp qw(read_file);

my $password = 'dwimmer';

my $run = start($password);


eval "use Test::More";
require Test::WWW::Mechanize;
plan(skip_all => 'Unsupported OS') if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";

plan(tests => 2);

my $w = Test::WWW::Mechanize->new;
$w->get_ok($url);

my $u = Test::WWW::Mechanize->new;
$u->get_ok($url);

