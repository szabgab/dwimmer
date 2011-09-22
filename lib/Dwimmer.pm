package Dwimmer;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.1101';

use Data::Dumper qw(Dumper);
use Dwimmer::DB;
use Dwimmer::Tools qw(_get_db _get_site read_file);

use Template;

load_app 'Dwimmer::Admin', prefix => "/_dwimmer";
 
my %open = map { $_ => 1 } qw(/_dwimmer/login.json /_dwimmer/session.json /poll);

hook before => sub {
    my $path = request->path_info;
    return if $open{$path};
    return if $path !~ m{/_}; # only the pages starting with /_ are management pages that need restriction

    if (not session->{logged_in}) {
        if ($path =~ /json$/) {
            request->path_info('/_dwimmer/needs_login.json');
        } else {
            request->path_info('/_dwimmer/needs_login');
        }
    }
    return;
};


sub route_index {
    my ($site_name, $site) = _get_site();
    return "Could not find site called '$site_name' in the database" if not $site;

    my $path = request->path_info;
    my $data = Dwimmer::Admin::get_page_data($site, $path);
    if ($data) {
        $data->{body} =~ s{\[(\w+)://([^]]+)\]}{_process($1, $2)}eg;
        
        $data->{body} =~ s{\[([\w .\$@%]+)\]}{<a href="$1">$1</a>}g;
        return Dwimmer::Admin::render_response('index', { page => $data });
    } else {
        return Dwimmer::Admin::render_response('error', { page_does_not_exist => 1 });
    }
};
get qr{^/([a-zA-Z0-9][\w .\$@%]*)?$} => \&route_index;

post '/poll' => sub {
    my $id = params->{id};
    return Dwimmer::Admin::render_response('error', { invalid_poll_id => $id })
        if $id !~ /^[\w-]+$/;
    
    my $json_file = path(config->{appdir}, 'polls', "$id.json");
    return Dwimmer::Admin::render_response('error', { poll_not_found => $id })
        if not -e $json_file;
    my $log_file = path(config->{appdir}, 'polls', "$id.txt");
    my $data = to_json params();
    if (open my $fh, '>>', $log_file) {
        print $fh $data, "\n"; 
        close;
    }
    return "OK";
};

sub _process {
    my ($scheme, $action) = @_;
    if ($scheme eq 'http' or $scheme eq 'https') {
        return qq{<a href="$scheme://$action">$action</a>};
    }

    if ($scheme eq 'poll') {
        if ($action !~ m{^[\w-]+$}) {
            return qq{Invalid poll name "$action"};
        }
        my $json_file = path(config->{appdir}, 'polls', "$action.json");
        
        if (not -e $json_file) {
            debug("File '$json_file' not found");
            return "Poll Not found";
        }
        my $data = eval { from_json scalar read_file $json_file };
        if ($@) {
            debug("Could not read json file '$json_file': $@");
            return "Could not read poll data";
        }

       my $html;
       open my $out, '>', \$html or die;
        my $t = Template->new(
            ABSOLUTE => 1,
#                encoding:  'utf8'
                START_TAG => '<%',
                END_TAG   =>'%>',
        );
        #return path(config->{appdir}, 'views', 'poll.tt') . -s path(config->{appdir}, 'views', 'poll.tt');
        $t->process(path(config->{appdir}, 'views', 'poll.tt'), {poll => $data}, $out);
        #use Capture::Tiny qw();
        #my ($out, $err) = Capture::Tiny::capture { $t->process(path(config->{appdir}, 'views', 'poll.tt'), {poll => $data}) };
        close $out;
        return $html;
    }

    return qq{Unknown scheme: "$scheme"};
}

true;

=head1 NAME

Dwimmer - A platform to develop things

=head1 COPYRIGHT

(c) 2011 Gabor Szabo

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2011 Gabor Szabo
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
