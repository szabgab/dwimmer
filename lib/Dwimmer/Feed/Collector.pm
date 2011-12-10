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
			alarm 0;
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
				eval {
					# checking for new hostname
					my $hostname = $entry->link;
					$hostname =~ s{^(https?://[^/]+).*}{$1};
					#main::LOG("HOST: $hostname");
					if ( not $self->db->find( link => "$hostname%" ) ) {
						main::LOG("ALERT: new hostname ($hostname) in URL: " . $entry->link);
						use MIME::Lite   ();
						my $msg = MIME::Lite->new(
							From    => 'dwimmer@dwimmer.com',
							To      => 'szabgab@gmail.com',
							Subject => "Dwimmer: new URL noticed $hostname",
							Data    => $entry->link,
						);
						$msg->send;
					}
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
				};
				if ($@) {
					main::LOG("EXCEPTION $@");
				}

			}
		};
		alarm 0;
		if ($@) {
			main::LOG("EXCEPTION $@");
		}
	}
}

# should be in its own class?
# plan: N item on front page or last N days?
# every day gets its own page in archice/YYYY/MM/DD
sub generate_html {
	my ($self, $dir) = @_;
	die if not $dir or not -d $dir;

	my $FRONT = 10;
	my $entries = $self->db->get_all_entries;
	use List::Util qw(min);
	use Template;
	my $size = min($FRONT, scalar @$entries);
	my @front = @$entries[0 .. $size-1];
	#die scalar @front;

my $template = <<'TEMPLATE';
<html>
<head>
<title>Perlsphere - the Perl blog aggregator</title>
</head>
<body>
[% FOR e IN entries %]
  <h2><a href="[% e.link %]">[% e.title %]</a></h2>
  <div class="entry">
  [% e.summary %]
  </div>
  <div class="permalink">For the full article visit <a href="[% e.link %]">[% e.title %]</a></div>
[% END %]

</body>
</html>
TEMPLATE

	my $t = Template->new();
    $t->process(\$template, {entries => \@front}, "$dir/index.html") or die $t->error;
	#foreach my $e (@$entries) {
	#	print $e->{issued}, "\n";
	#}

	return;
}



1;

