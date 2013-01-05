use strict;
use warnings;

use Test::More;
use Test::Script;

my @scripts = grep {!/poll/} glob "script/*";
diag explain \@scripts;

plan tests => scalar @scripts;
foreach my $scr (@scripts) {
    script_compiles($scr);
}
