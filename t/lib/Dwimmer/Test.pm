package t::lib::Dwimmer::Test;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(start stop $admin_mail @users);

#use File::Basename qw(dirname);

use File::Spec;
use File::Temp qw(tempdir);

my $process;

sub start {
    my ($password) = @_;

my $dir = tempdir( CLEANUP => 1 );

$ENV{DWIMMER_TEST} = 1;
$ENV{DWIMMER_PORT} = 3001;
$ENV{DWIMMER_MAIL} = File::Spec->catfile($dir, 'mail.txt');

our $admin_mail = 'test@dwimmer.org';

our @users = (
	{
		uname    => 'tester',
		fname    => 'foo',
		lname    => 'bar',
		email    => 'test@dwimmer.org',
		password => 'dwimmer',
	},
);

my $root = File::Spec->catdir($dir, 'dwimmer');
system "$^X -Ilib script/dwimmer_setup.pl --root $root --email $admin_mail --password $password";


    if ($^O =~ /win32/i) {
        require Win32::Process;
        #import Win32::Process;

        Win32::Process::Create($process, $^X,
                            "perl -Ilib -It\\lib $root\\bin\\app.pl",
                            0,
                            Win32::Process::NORMAL_PRIORITY_CLASS(),
                            ".") || die ErrorReport();
    } else {
        die "Unsupported OS";
    }

    return;
}

sub stop {
    return if not $process;
    if ($^O =~ /win32/i) {
        $process->Kill(0);
    } else {
        warn "Unsupported OS";
    }
}

END {
    stop();
}



1;
