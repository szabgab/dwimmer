package Dwimmer::Feed::Admin;
use Moose;

use 5.008005;

use Dwimmer::Feed::DB;

use Data::Dumper qw(Dumper);

has 'store'   => (is => 'ro', isa => 'Str', required => 1);
has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}

sub list {
	my ($self, $filter) = @_;
	my $sources = $self->db->get_sources;
	foreach my $s (@$sources) {
		next if $filter and $s->{feed} !~ /$filter/ and $s->{url} !~ /$filter/;
		print Dumper $s;
	}
	return;
}


1;

