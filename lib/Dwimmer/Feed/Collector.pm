package Dwimmer::Feed::Collector;
use Moose;

use File::Slurp  qw(read_file);
use JSON         qw(from_json);
use XML::Feed    ();

has 'sources' => (is => 'ro', isa => 'Str', required => 1);
has 'store'   => (is => 'ro', isa => 'Str', required => 1);
has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}

sub collect {
	my ($self) = @_;

	my $sources = from_json scalar read_file $self->sources;
	main::LOG("sources loaded");


	for my $e ( @{ $sources->{feeds}{entries} } ) {
		if (not $e->{feed}) {
			main::LOG("ERROR: No feed for $e->{title}");
			next;
		}
		eval {
			local $SIG{ALRM} = sub { die 'TIMEOUT' };
			alarm 10;

			main::LOG("Processing $e->{title}");
			my $feed = XML::Feed->parse(URI->new($e->{feed}));
			if (not $feed) {
				main::LOG("ERROR: " . XML::Feed->errstr);
				next;
			}
			if ($feed->title) {
				main::LOG("Title: " . $feed->title);
			} else {
				main::LOG("WARN: no title");
			}
			for my $entry ($feed->entries) {
				#print $entry, "\n";
				if ( not $self->db->find( link => $entry->link ) ) {
					my %current = (
						source    => $e->{feed},
						link      => $entry->link,
						author    => ($entry->{author} || ''),
						remote_id => ($entry->{id} || ''),
						issued    => $entry->issued->ymd . ' ' . $entry->issued->hms,
						title     => ($entry->title || ''),
						summary   => ($entry->summary->body || ''),
						content   => ($entry->content->body || ''),
						tags    => '', #$entry->tags,
					);
					main::LOG("Adding $current{link}");
					$self->db->add(%current);
				}
			}
		};
		alarm(0);
		if ($@) {
			main::LOG("EXCEPTION $@");
		}
	}
}

1;
