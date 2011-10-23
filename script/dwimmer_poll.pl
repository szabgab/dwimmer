#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use File::Slurp  qw(read_file write_file);
use JSON         qw(from_json to_json);
use Pod::Usage   qw(pod2usage);

my ($in, $out, $result) = @ARGV;

pod2usage if not $in or not -e $in;
pod2usage if not $out;
pod2usage if not $result;

my $data = read_file($in);
my @p = split  /^$/m, $data;
#print scalar @p;
#print $p[0];

my %MAP;
my %count = (SID => 0, IP => 0);
my %DUPLICATE;
my @all;
my %RESULT;

foreach my $json (@p) {
	next if $json =~ /^\s*$/;
#	print $json;
#	print "-----------------------\n";
	my $d = from_json($json);
	foreach my $f (qw(SID IP)) {
		if (not $MAP{$f}{ $d->{$f} }) {
			$count{$f}++;
			$MAP{$f}{ $d->{$f} } = $count{$f};
		} else {
			$DUPLICATE{$f}++;
			next if $f eq 'SID';
		}
		$d->{$f} = $MAP{$f}{ $d->{$f} };
		push @all, $d;
	}

	foreach my $key (keys %$d) {
		next if $key =~ /^(SID|TS|IP)$/;
		if ($key =~ /^other__/ and $d->{$key}) {
			push @{ $RESULT{$key} }, $d->{$key};
		}
	}
}
write_file($out, to_json \@all, { pretty => 1, utf8 => 1 });

write_file($result, Dumper \%RESULT);

print Dumper \%DUPLICATE;

=head1 NAME

Sanitize a poll file

=head1 SYNOPSIS


PARAMETERS:
   IN_FILE OUT_FILE RESULT_FILE

=cut


