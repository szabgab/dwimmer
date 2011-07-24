package Dwimmer;
use Dancer ':syntax';

our $VERSION = '0.01';
use Data::Dumper;

use Dwimmer::DB;
use Dwimmer::Tools qw(sha1_base64);

###### hooks 
hook before_template => sub {
    my $tokens = shift;
    foreach my $field (qw(logged_in username)) {
        $tokens->{$field} = session->{$field};
    };
    return;
};


###### routes
my @error_pages = qw(invalid_login not_verified);

sub route_index {
#    my $db = _get_db();
#    my $admin = $db->resultset('User')->find( {name => 'admin'});
    template 'index';
};
get '/' => \&route_index;
get '/index' => \&route_index; # temp measure to allow the current configuration to work in CGI mode

post '/login' => sub {
    my $username = params->{username};
    my $password = params->{password};
    
    return redirect '/invalid_login' if not $username or not $password;

    my $db = _get_db();
    my $user = $db->resultset('User')->find( {name => $username});
    return redirect '/invalid_login' if not $user;

    my $sha1 = sha1_base64($password);
    return redirect '/invalid_login' if $sha1 ne $user->sha1;
    
    return redirect '/not_verified' if not $user->verified;

    session username => $username;
    session logged_in => 1;


    # redirect to the referer except if that was 
    # the logout page or one of the error pages.
    my $referer = request->referer;
    my $host    = request->host;

    my $ref_path = '';
    if ($referer =~ m{^https?://$host(.*)}) {
        $ref_path = $1;
    } else {
        return redirect '/';    
    }

    my $noland_pages = join '|', ('logout', @error_pages);
    if ($ref_path =~ m{^/($noland_pages)}) {
        return redirect '/';
    }

    redirect $referer;
};

get '/logout' => sub {
     session->destroy;
     template 'goodbye';
};

get '/page' => sub {
    template 'page';
};

# post '/page' =>  sub {
    # my $now   = time;
    # $data->{$now} = {
        # title => params->{title},
        # text  => params->{text},
    # };
# 
    # redirect '/';
# };

# static pages

foreach my $page (@error_pages) {
    get "/$page" => sub {
        template 'invalid_login';
    };
}


###### helper methods

sub _get_db {
    my $dbfile = config->{dwimmer}{dbfile};
    Dwimmer::DB->connect("dbi:SQLite:dbname=$dbfile", '', '');
};

true;

