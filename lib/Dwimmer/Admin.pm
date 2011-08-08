package Dwimmer::Admin;
use Dancer ':syntax';

use 5.008005;

our $VERSION = '0.01';

use Data::Dumper    qw(Dumper);
use Email::Valid    ();
use MIME::Lite      ();
use String::Random  ();
use Template        ();

use Dwimmer::DB;
use Dwimmer::Tools qw(sha1_base64 _get_db _get_site);


sub include_session {
    my ($data) = @_;

    if (session->{logged_in}) {
        foreach my $field (qw(logged_in username userid)) {
            $data->{$field} = session->{$field};
        };
    }

    return;
}

sub render_response {
    my ($template, $data) = @_;

    $data ||= {};
    include_session($data);
    
    debug('render_response  ' . request->content_type );
    $data->{dwimmer_version} = $VERSION;
    my $content_type = request->content_type || params->{content_type} || '';
    if ($content_type =~ /json/ or request->{path} =~ /\.json/) {
       content_type 'text/plain';
       debug('json', $data);
       return to_json $data, { utf8 => 0, convert_blessed => 1, allow_blessed => 1 };
    } else {
       return template $template, $data;
    }
}

sub get_page_data {
    my ($site, $path) = @_;

    my $db = _get_db();
    my $page = $db->resultset('Page')->find( {siteid => $site->id, filename => $path} );

    return if not $page;
    return {
            title  => $page->title,
            body   => $page->body,
            author => $page->author->name,
            filename => $page->filename,
    };


}

###### routes

get '/page.json' => sub {
    my ($site_name, $site) = _get_site();
    my $path = params->{filename};
    return to_json {error => 'no_site_found' } if not $site;
    
    my $data = get_page_data($site, $path);
    if ($data) {
        return to_json { page => $data };
    } else {
        return to_json { error => 'page_does_not_exist' };
    }
};

post '/save_page.json' => sub {
    my ($site_name, $site) = _get_site();

    return to_json { error => "no_site" } if not $site;
    my $filename = params->{filename};
    return to_json { error => "no_file_supplied" } if not $filename;

    # TODO check if the user has the right to save this page!
#    debug( params->{editor_body} );
#    debug( params->{editor_title} );
    my $db = _get_db();
    my $page = $db->resultset('Page')->find( {siteid => $site->id, filename => $filename});

    my $create = params->{create};
    if ($page) {
        if ($create) {
            return to_json { error => 'page_already_exists' };
        } else {
            $page->body( params->{editor_body} );
            $page->title( params->{editor_title} );
            # TODO save to history
            # TODO update author
            # TODO update timestamp
            $page->update;
            return to_json { success => 1 };
        }
    } else {
        if ($create) {
            my $time = time;
            $db->resultset('Page')->create({
                title    => params->{editor_title},
                filename => $filename,
                body     => params->{editor_body},
                author   => session->{userid},
                siteid   => $site->id,
                timestamp => $time,
            });
            return to_json { success => 1 };
        } else {
            return to_json { error => 'page_does_not_exist' };
        }
    }
};

post '/login.json' => sub {
    my $username = params->{username};
    my $password = params->{password};
    
    return to_json { error => 'missing_username' } if not $username;
    return to_json { error => 'missing_password' } if not $password;

    my $db = _get_db();
    my $user = $db->resultset('User')->find( {name => $username});
    return to_json { error => 'no_such_user' } if not $user;

    my $sha1 = sha1_base64($password);
    return to_json { error => 'invalid_password' } if $sha1 ne $user->sha1;
  
    return { error => 'not_verified' } if not $user->verified;

    session username => $username;
    session userid   => $user->id;
    session logged_in => 1;

    my $data = { success => 1 };
    include_session($data);
    return to_json $data;
};

get '/logout.json' => sub {
     session->destroy;
     return to_json {success => 1};
};

get '/list_users.json' => sub {
    my $db = _get_db();
    my @users = map { { id => $_->id, name => $_->name }  }  $db->resultset('User')->all();
    return to_json { users => \@users };
};

get '/needs_login' => sub {
    return render_response 'error', { not_logged_in => 1 };
};
get '/needs_login.json' => sub {
    return render_response 'error', { error => 'not_logged_in' };
};

get '/session.json' => sub {
    my $data = {logged_in => 0};
    include_session($data);
    return to_json $data;
};

get '/get_user.json' => sub {
    my $id = params->{id};
    return to_json { error => 'no_id' } if not defined $id;
    my $db = _get_db();
    my $user = $db->resultset('User')->find( $id );
    return to_josn { error => 'no_such_user' } if not defined $id;
    my @fields = qw(id name email fname lname verified register_ts);
    my %data = map { $_ => $user->$_ } @fields;
    return to_json \%data;
};

post '/add_user.json' => sub {
    my %args;
    foreach my $field ( qw(uname fname lname email pw1 pw2 verify) ) {
        $args{$field} = params->{$field} || '';
        trim($args{$field});
    }
    #return $args{verify};

    if ($args{pw1} eq '' and $args{pw2} eq '') {
        $args{pw1} = $args{pw2} = String::Random->new->randregex('[a-zA-Z0-9]{10}');
    }
    $args{tos} = 'on'; # TODO not really the right thing, mark in the database that the user was added by the admin

    return to_json { error => 'invalid_verify' } if $args{verify} !~ /^(send_email|verified)$/;

    my $ret = register_user(%args);
    return to_json { error => $ret } if $ret;

    return to_json { success => 1 };
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
    return render_response 'error', {$ret => 1} if $ret;

    redirect '/register_done';
};



sub register_user {
    my %args = @_;
    # validate
    $args{email} = lc $args{email};

    my $db = _get_db();
    if (length $args{uname} < 2 or $args{uname} =~ /[^\w.-]/) {
        return 'invalid_username';
    }
    my $user = $db->resultset('User')->find( { name => $args{uname} });
    if ($user) {
        return 'username_taken';
    }
    $user = $db->resultset('User')->find( {email => $args{email}});
    if ($user) {
        return 'email_used';
    }
    if (length $args{pw1} < 5) {
        return 'short_password';
    }
    if ($args{pw1} ne $args{pw2}) {
        return 'passwords_dont_match';
    }
    if ($args{tos} ne 'on') {
        return 'no_tos';
    };

    # insert new user
    my $time = time;
    my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $user = $db->resultset('User')->create({
        name  => $args{uname},
        email => $args{email},
        sha1  => sha1_base64($args{pw1}),
        validation_key => $validation_key,
        verified => ($args{verify} eq 'verified' ? 1 : 0),
        register_ts => $time,
    });

    if ($args{verify} eq 'send_email') {
        my $template = read_file(path(config->{appdir}, 'views', 'register_verify_mail.tt'));
        if ($user) {
            my $url = 'http://' . request->host . "/finish_registration?uname=$args{uname}&code=$validation_key";
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


get '/get_pages.json' => sub {
    my ($site_name, $site) = _get_site();
    my $db = _get_db();
    my @res = $db->resultset('Page')->search( {siteid => $site->id} );

    my @rows = map { { id => $_->id, filename => $_->filename, title => $_->title } }  @res;
    return to_json { rows => \@rows };
};


###### helper methods


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

