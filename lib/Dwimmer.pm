package Dwimmer;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.01';

use Data::Dumper;
use Email::Valid;
use MIME::Lite;
use String::Random;
use Template;

use Dwimmer::DB;
use Dwimmer::Tools qw(sha1_base64);


sub render_response {
    my ($template, $data) = @_;

    $data ||= {};
    foreach my $field (qw(logged_in username)) {
        $data->{$field} = session->{$field};
    };
    $data->{dwimmer_version} = $VERSION;
    my $content_type = request->content_type || params->{content_type} || '';
    if ($content_type =~ /json/) {
       content_type 'text/plain';
       return to_json $data, {utf8 => 0};
    } else {
       return template $template, $data;
    }
}


###### routes
my @error_pages = qw(invalid_login not_verified);

sub route_index {
#    my $db = _get_db();
#    my $admin = $db->resultset('User')->find( {name => 'admin'});
    render_response 'index';
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
     render_response 'goodbye';
};

get '/page' => sub {
    render_response 'page';
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

get '/list_users' => sub {
    my $db = _get_db();
    my @users = $db->resultset('User')->all(); #{ select => [ qw/id uname/ ] });
    #my $html = $users[0]->uname;
    #return $html;
    render_response 'list_users', {users => \@users};
};

# static pages , 
foreach my $page (@error_pages, 'add_user') {
    get "/$page" => sub {
        render_response $page;
    };
}

post '/add_user' => sub {
    my %args;
    foreach my $field ( qw(uname fname lname email pw verify) ) {
        $args{$field} = params->{$field} || '';
        trim($args{$field});
    }

    $args{pw} ||= String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $args{pw1} = $args{pw2} = delete $args{pw};
    $args{tos} = 'on'; # not really the right thing

    return 'invalid verify' if $args{verify} !~ /^(send_email|verified)$/;

    my $ret = register_user(%args);
    return $ret if $ret;


    render_response '/user_added';
};

get '/register' => sub {
    render_response 'register';
};

post '/register' => sub {
    my %args;
    foreach my $field ( qw(uname fname lname email pw1 pw2 verify tos) ) {
        $args{$field} = params->{$field} || '';
        trim($args{$field});
    }
    $args{verify} = 'send_email';

    my $ret = register_user(%args);
    return $ret if $ret;

    redirect '/register_done';
};



sub register_user {
    my %args = @_;
    # validate
    $args{email} = lc $args{email};

    my $db = _get_db();
    if (length $args{uname} < 2 or $args{uname} =~ /[^\w.-]/) {
        return 'Invalid username';
    }
    my $user = $db->resultset('User')->find( { name => $args{uname} });
    if ($user) {
        return 'This username is already taken';
    }
    $user = $db->resultset('User')->find( {email => $args{email}});
    if ($user) {
        return 'This email was already used. If you already have a registration but dont remember the password, you can <a href="/reset_password">reset</a> it here.';
    }
    if (length $args{pw1} < 5) {
        return 'Password is too short. It needs at least 5 characters';
    }
    if ($args{pw1} ne $args{pw2}) {
        return 'Passwords did not match';
    }
    if ($args{tos} ne 'on') {
        return 'Sorry we cannot register you if you dont agree to our Terms of Service';
    };

    # insert new user
    my $time = time;
    my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $user = $db->resultset('User')->create({
        name  => $args{uname},
        email => $args{email},
        sha1  => sha1_base64($args{pw1}),
        validation_key => $validation_key,
    });

    if ($args{verify} eq 'send_email') {
        my $template = read_file(path(config->{appdir}, 'views', 'register_verify_mail.tt'));
        if ($user) {
            my $url = 'http://' . request->host . "/finish_registration?uname=$args{uname}&code=$validation_key";
            #my $template = read_file 
            my $message = ''; # template 'register_verify_mail', { url => $url };
            my $msg = MIME::Lite->new(
                From    => 'gabor@szabgab.com',
                To      => $args{email},
                Subject => 'Verify your registration to Dwimmer!',
                Data    => $message,
            );
            $msg->send;
        }
    } else {
        # set the verified bit?
    }

    return;
}


get '/manage' => sub {
    render_response 'manage';
};


get '/edit_this_page' => sub {
    return 'edit this page';
};




###### helper methods

sub _get_db {
    my $dbfile = path(config->{appdir}, 'db', 'dwimmer.db');
    Dwimmer::DB->connect("dbi:SQLite:dbname=$dbfile", '', '');
};

sub trim {  $_[0] =~ s/^\s+|\s+$//g };

sub read_file {
    my $file = shift;
    open my $fh, '<', $file or die "Could not open '$file' $!";
    local $/ = undef;
    my $cont = <$fh>;
    close $fh;
    return $cont;
}

true;

