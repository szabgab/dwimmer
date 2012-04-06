package Dwimmer::Feed::Admin;
use Moose;

use 5.008005;

our $VERSION = '0.27';

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
	my ($self, %args) = @_;
	my $sources = $self->db->get_sources;
	foreach my $s (@$sources) {
		my $show;
		if ($args{filter}) {
			foreach my $field (qw(feed url status title)) {
				$show++ if $s->{$field} =~ /$args{filter}/i;
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

sub update {
	my ($self, %args) = @_;

	my $s = $self->db->get_source_by_id($args{id});
	if (not $s) {
		die "ID '$args{id}' not found\n";
	}

	_dump($self->db->get_source_by_id($args{id}));
	$self->db->update($args{id}, $args{field}, $args{value});
	_dump($self->db->get_source_by_id($args{id}));

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
	local $Data::Dumper::Sortkeys = 1;
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


sub list_config {
	my ($self) = @_;

	use Dwimmer::Feed::Config;
	my $config = Dwimmer::Feed::Config->get_config($self->db);
	_dump($config);
}

1;

