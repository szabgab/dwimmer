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
		my $show;
		if ($filter) {
			foreach my $field (qw(feed url status title)) {
				$show++ if $s->{$field} =~ /$filter/i;
			}
		} else {
			$show++;
		}
		if ($show) {
			_dump($s);
		}
	}
	return;
}

sub enable {
	my ($self, $id) = @_;
	return $self->able($id, 1);
}
sub disable {
	my ($self, $id) = @_;
	return $self->able($id, 0);
}


sub able {
	my ($self, $id, $able) = @_;

	my $s = $self->db->get_source_by_id($id);
	if (not $s) {
		die "ID '$id' not found\n";
	}
	_dump($s);
	$self->db->able($id, $able);
	_dump($self->db->get_source_by_id($id));

	return;
}

sub update {
	my ($self, $id, $field, $value) = @_;
	_dump($self->db->get_source_by_id($id));
	$self->db->update($id, $field, $value);
	_dump($self->db->get_source_by_id($id));

	return;
}

sub add {
	my ($self) = @_;
	my %data;
	$data{url}     = prompt('URL');
	$data{feed}    = prompt('Feed (Atom or RSS)');
	$data{title}   = prompt('Title');
	$data{twitter} = prompt('Twitter');
	$data{status}  = 'enabled';
	$data{comment} = prompt('Comment');
	$data{twitter} =~ s/\@//;

	my $id = $self->db->add_source(\%data);
	_dump($self->db->get_source_by_id($id));

	return;
}


sub _dump {
	print Dumper shift;
	return;
}

sub prompt {
	my ($text) = @_;

	print "$text :";
	my $input = <STDIN>;
	chomp $input;

	return $input;
}


1;

