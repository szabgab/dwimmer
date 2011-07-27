package Dwimmer;
use Dancer ':syntax';

our $VERSION = '0.01';

use Data::Dumper;
use Email::Valid;
use MIME::Lite;
use String::Random;
use Template;

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
    my $referer = request->referer || '';
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

# static pages , 
foreach my $page (@error_pages, 'add_user') {
    get "/$page" => sub {
        template $page;
    };
}

get '/list_users' => sub {
    my $db = _get_db();
    my @users = $db->resultset('User')->all(); #{ select => [ qw/id uname/ ] });
    #my $html = $users[0]->uname;
    #return $html;
    template 'list_users', {users => \@users};
};

get '/register' => sub {
    template 'register';
};

post '/register' => sub {
    # validate
    my $uname  = params->{uname}    || '';
    my $email  = lc params->{email} || '';
    my $pw1    = params->{pw1}      || '';
    my $pw2    = params->{pw2}      || '';
    my $tos    = params->{tos}      || '';

    my $db = _get_db();
    $uname =~ s/^\s+|\s+$//g;
    if (length $uname < 2 or $uname =~ /[^\w.-]/) {
        return 'Invalid username';
    }
    my $user = $db->resultset('User')->find( {name => $uname});
    if ($user) {
        return 'This username is already taken';
    }
    $user = $db->resultset('User')->find( {email => $email});
    if ($user) {
        return 'This email was already used. Would you like to reset your password?';
    }
    if (length $pw1 < 5) {
        return 'Password is too short. It needs at least 5 characters';
    }
    if ($pw1 ne $pw2) {
        return 'Passwords did not match';
    }
    if ($tos ne 'on') {
        return 'Sorry we cannot register you if you dont agree to our Terms of Service';
    };

    # insert new user
    my $time = time;
    my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $user = $db->resultset('User')->create({
        name  => $uname,
        email => $email,
        sha1  => sha1_base64($pw1),
        validation_key => $validation_key,
    });
    
    my $template = read_file(path(config->{appdir}, 'view', 'register_verify_mail'));
    if ($user) {
        my $url = 'http://' . request->host . "/finish_registration?uname=$uname&code=$validation_key";
        #my $template = read_file 
        my $message = ''; # template 'register_verify_mail', { url => $url };
        my $msg = MIME::Lite->new(
            From    => 'gabor@szabgab.com',
            To      => $email,
            Subject => 'Verify your registration to Dwimmer!',
            Data    => $message,
        );
        $msg->send;
    }
    redirect '/register_done';
};

get '/manage' => sub {
    template 'manage';
};


get '/edit_this_page' => sub {
    return 'edit this page';
};




###### helper methods

sub _get_db {
    my $dbfile = path(config->{appdir}, 'db', 'dwimmer.db');
    Dwimmer::DB->connect("dbi:SQLite:dbname=$dbfile", '', '');
};

true;

