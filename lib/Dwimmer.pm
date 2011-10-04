package Dwimmer;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.01';

use Dwimmer::DB;
use Dwimmer::Tools qw(_get_db _get_site);

load_app 'Dwimmer::Admin', prefix => "/_dwimmer";

# list of pages that can be accessed withot any login 
my %open = map { $_ => 1 } qw(/_dwimmer/login.json /_dwimmer/session.json /_dwimmer/register_email.json /_dwimmer/validate_email.json);

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
        $data->{body} =~ s{\[(\w+)\]}{<a href="$1">$1</a>}g;
        return Dwimmer::Admin::render_response('index', { page => $data });
    } else {
        return Dwimmer::Admin::render_response('error', { page_does_not_exist => 1 });
    }
};
get qr{^/([a-zA-Z0-9]\w*)?$} => \&route_index;


true;
