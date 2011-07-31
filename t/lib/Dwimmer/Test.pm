package t::lib::Dwimmer::Test;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(start stop);

my $process;

sub start {
    my ($root) = @_;

    if ($^O =~ /win32/i) {
        require Win32::Process;
        #import Win32::Process;

        Win32::Process::Create($process, $^X,
                            "perl -It\\lib $root\\bin\\app.pl",
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
