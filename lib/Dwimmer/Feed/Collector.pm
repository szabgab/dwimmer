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
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en-us">
<head>
<title>Perlsphere - the Perl blog aggregator</title>
</head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<body>
<style>
html {
  margin: 0;
  padding: 0;
}
body {
  margin: 0;
  padding: 0;
  /* text-align: center;*/
  width: 800px;
  margin-left: auto;
  margin-right: auto;
  font-size: 16px;

}
#header_text {
}

.entry {
  background-color: #DDD;
  padding: 10px;
  margin-top: 10px;
  margin-bottom: 10px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}
.title {
  font-size: 24px;
  font-weight: bold;
}
.title a {
   text-decoration: none;
}
</style>


  <h1>Perlsphere</h1>
  <div id="header_text">
  The Perl firehose! The Web's biggest collection of Perl blogs.
  If you'd like your Perl blog or tech blog's Perl category to appear here, send mail to szabgab@gmail.com
  (Please have several posts already).
  </div>

[% FOR e IN entries %]
  <div class="entry">
  <div class="title"><a href="[% e.link %]">[% e.title %]</a></div>
  <div class="summary">
  [% e.summary %]
  </div>
  <div class="date">Posted on [% e.issued %]</div>
  <div class="permalink">For the full article visit <a href="[% e.link %]">[% e.title %]</a></div>
  </div>
[% END %]

</div>
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

