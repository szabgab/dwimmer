#!/usr/bin/env perl
use Dancer;
if ($ENV{DWIMMER_TEST}) {
	set log => 'warning';
	set startup_info => 0;
}
use Dwimmer;
dance;
