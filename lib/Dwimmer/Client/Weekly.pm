package Dwimmer::Client::Weekly;
use Moose;

extends 'Dwimmer::Client';

use JSON qw(from_json);

sub register_email {
	my ($self, $email) = @_;
	my $m = $self->mech;
#	$m->post( $self->host . "/_dwimmer/register_mail.json", { email => $email } );
	$m->get($self->host . '/_dwimmer/register_mail.json?email=' . $email);

	return from_json $m->content;
}

1;
