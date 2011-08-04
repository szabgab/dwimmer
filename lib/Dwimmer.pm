package Dwimmer;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.01';

use Dwimmer::DB;
use Dwimmer::Tools qw(_get_db _get_site);

load_app 'Dwimmer::Admin', prefix => "/_dwimmer";
 
my %open = map { $_ => 1 } qw(/ /_dwimmer/login /_dwimmer/login.json);

hook before => sub {
    my $path = request->path_info;
    return if $open{$path};
    
    if (not session->{logged_in}) {
        request->path_info('/_dwimmer/needs_login');
    }
    return;
};


sub route_index {
    my $db = _get_db();


    my ($site_name, $site) = _get_site();
    return "Could not find site called '$site_name' in the database" if not $site;

    my $path = request->path_info;
    my $page = $db->resultset('Page')->find( {siteid => $site->id, filename => $path});

    my %data= (
        title  => $page->title,
        body   => $page->body,
        author => $page->author->name,
        filename => $page->filename,
    );
    Dwimmer::Admin::render_response('index', {page => \%data});
};
get '/' => \&route_index;
get '/index' => \&route_index; # temp measure to allow the current configuration to work in CGI mode


true;
