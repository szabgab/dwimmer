package Dwimmer::Feed::Collector;
use Moose;

use 5.008005;

our $VERSION = '0.24';

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

sub get_sources {
	my ($self) = @_;
	
	return from_json scalar read_file $self->sources;
}

sub collect {
	my ($self) = @_;

	my $sources = $self->get_sources();
	main::LOG("sources loaded");


	for my $e ( @{ $sources->{feeds}{entries} } ) {
		next if not $e->{status} or $e->{status} ne 'enabled';
		if (not $e->{feed}) {
			main::LOG("ERROR: No feed for $e->{title}");
			next;
		}
		my $feed;
		eval {
			local $SIG{ALRM} = sub { die 'TIMEOUT' };
			alarm 10;

			main::LOG("Processing $e->{title}");
			$feed = XML::Feed->parse(URI->new($e->{feed}));
		};
		my $err = $@;
		alarm 0;
		if ($err) {
			main::LOG("EXCEPTION $err");
		}
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
	}
}


my $FRONT_PAGE_SIZE = 20;
my $FEED_SIZE = 20;
my $TITLE = "Perlsphere";
my $URL   = "http://feed.szabgab.com/";
my $DESCRIPTION = 'The largest source of Perl related news';
my $ADMIN_NAME  = 'Gabor Szabo';
my $ADMIN_EMAIL = 'szabgab@gmail.com';

sub get_entries {
	my ($self, $size) = @_;

	my $entries = $self->db->get_all_entries;
	use List::Util qw(min);
	use Template;
	$size = min($size, scalar @$entries);
	my @front = @$entries[0 .. $size-1];

	return \@front;
}

# should be in its own class?
# plan: N item on front page or last N days?
# every day gets its own page in archice/YYYY/MM/DD
sub generate_html {
	my ($self, $dir) = @_;
	die if not $dir or not -d $dir;

	my $sources = $self->get_sources();

	my $entries = $self->get_entries($FRONT_PAGE_SIZE);

	use File::Basename qw(dirname);
	use Cwd qw(abs_path);
	my $root = dirname dirname abs_path $0;

	my $t = Template->new({ ABSOLUTE => 1, });
	$t->process("$root/views/feed_index.tt", {entries => $entries}, "$dir/index.html") or die $t->error;

	my %site = (
		url             => $URL,
		title           => $TITLE,
		description     => $DESCRIPTION,
		language        => 'en',
		admin_name      => $ADMIN_NAME,
		admin_email     => $ADMIN_EMAIL,
		id              => $URL,
		dwimmer_version => $VERSION,
	);

	$site{last_build_date} = localtime;
	
	$t->process("$root/views/feed_rss.tt", {entries => $entries, %site}, "$dir/rss.xml") or die $t->error;
	$t->process("$root/views/feed_atom.tt", {entries => $entries, %site}, "$dir/atom.xml") or die $t->error;
	$t->process("$root/views/feed_feeds.tt", $sources->{feeds}, "$dir/feeds.html") or die $t->error;

	return;
}


1;

