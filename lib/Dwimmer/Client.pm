package Dwimmer::Client;
use Moose;

use WWW::Mechanize;
use JSON qw(from_json);

has host => (is => 'ro', isa => 'Str', required => 1);
has mech => (is => 'rw', isa => 'WWW::Mechanize', default => sub { WWW::Mechanize->new } );


our $VERSION = '0.01';

sub login {
	my ($self, $username, $password) = @_;
	my $m = $self->mech;
	$m->post($self->host . '/_dwimmer/login.json', {
		username => $username,
		password => $password,
	});
	return from_json $m->content;
}

sub logout {
	my ($self) = @_;
	my $m = $self->mech;
	$m->get($self->host . '/_dwimmer/logout.json');
	return from_json $m->content;
}

sub list_users {
	my ($self) = @_;
	my $m = $self->mech;
	$m->get($self->host . '/_dwimmer/list_users.json');
	return from_json $m->content;
}

# parameters can be    id => 1
sub get_user {
	my ($self, %args) = @_;
	my $m = $self->mech;
	$m->get($self->host . "/_dwimmer/get_user.json?id=$args{id}");
	return from_json $m->content;
}

sub add_user {
	my ($self, %args) = @_;
	my $m = $self->mech;
	$m->post( $self->host . "/_dwimmer/add_user.json", \%args );
	return from_json $m->content;
}

sub get_session {
	my ($self) = @_;
	my $m = $self->mech;
	$m->get( $self->host . "/_dwimmer/session.json" );
	return from_json $m->content;
}


sub get_pages {
	my ($self) = @_;
	my $m = $self->mech;
	$m->get($self->host . '/_dwimmer/get_pages.json');
	return from_json $m->content;
}

sub get_page {
	my ($self, $filename, $revision) = @_;
	my $m = $self->mech;
	my $url = $self->host . '/_dwimmer/page.json?filename=' . $filename;
	$url .= "&revision=$revision" if defined $revision;
	$m->get($url);
	return from_json $m->content;
}

sub save_page {
	my ($self, %args) = @_;
	my $m = $self->mech;
	$args{editor_body} = delete $args{body};
	$args{editor_title} = delete $args{title};
	$m->post( $self->host . "/_dwimmer/save_page.json", \%args );
	return from_json $m->content;
}


sub get_history {
	my ($self, $filename) = @_;
	my $m = $self->mech;
	$m->get($self->host . '/_dwimmer/history.json?filename=' . $filename);
	return from_json $m->content;
}

my %GET = map { $_ => $_ } qw(create_list fetch_lists register_email validate_email);

AUTOLOAD {
	our $AUTOLOAD;
	(my $sub = $AUTOLOAD) =~ s/^Dwimmer::Client:://;
	my ($self, %attr) = @_;

	if ($GET{$sub}) {
            my $params = join "&", map { "$_=$attr{$_}" } keys %attr;
	    my $m = $self->mech;
	    my $url = $self->host . "/_dwimmer/$GET{$sub}.json?$params";
	    #warn $url;
	    $m->get($url);

	    return from_json $m->content;
	}
	die "Could not locate method '$sub'\n";
}

1;

