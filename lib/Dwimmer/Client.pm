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

sub list_users {
	my ($self) = @_;
	my $m = $self->mech;
	$m->get($self->host . '/_dwimmer/list_users.json');
	return from_json $m->content;
}



1;
