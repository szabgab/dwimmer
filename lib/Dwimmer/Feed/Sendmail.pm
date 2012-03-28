package Dwimmer::Feed::Sendmail;
use Moose;

our $VERSION = '0.27';

use Encode       ();
use MIME::Lite   ();

has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');
has 'store'   => (is => 'ro', isa => 'Str', required => 1);

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}


sub send {
	my ($self) = @_;

	my $entries = $self->db->get_queue( 'mail' );
	my $sources = $self->db->get_sources;

	foreach my $e (@$entries) {
		my ($source) = grep { $_->{id} eq $e->{source_id} }  @$sources;

		# fix redirection and remove parts after path
		# This is temporarily here though it should be probably moved to the collector
		my $redirector = '';
		use LWP::UserAgent;
		my $ua = LWP::UserAgent->new;
		@{ $ua->requests_redirectable } = ();

		my $url = $e->{link};
		my $response = $ua->get($url);


		my $status = $response->status_line;
		$redirector .= qq{<p>Status: $status</p>\n};
		if ( $response->code == 301 ) {
			$url = $response->header('Location');
			$redirector .= qq{<p>Redirected to: <a href="$url">$url</a></p>\n};
		}
		my $uri = URI->new($url);
		$uri->fragment(undef);
		$uri->query(undef);

		$url = $uri->canonical;
		$redirector .= qq{<p>Canonical URL: $url</p>\n};
		if ($url ne $e->{link}) {
			$redirector .= qq{<h1><a href="$url">$e->{title}</a></h1>\n};
		}

		my $text = '';
		$text .= "Title: $e->{title}\n";
		$text .= "Link: $e->{link}\n\n";
		#$text .= "Source: $e->{source}\n\n";
		$text .= "Tags: $e->{tags}\n\n";
		$text .= "Author: $e->{author}\n\n";
		$text .= "Date: $e->{issued}\n\n";
		$text .= "Summary:\n$e->{summary}\n\n";
		#$text .=  Encode::encode('UTF-8', "Content:\n$e->{content}\n\n");
		#$text .= "-------------------------------\n\n";

		my $html = qq{<html><head><title></title></head><body>\n};
		$html .= qq{<h1><a href="$e->{link}">$e->{title}</a></h1>\n};
		$html .= qq{<p>Link: $e->{link}</p>\n};
		$html .= qq{<p>Entry ID: $e->{id}</p>\n};
		#$html .= qq{<p>Source ID: $e->{source_id}</p>\n};
		$html .= qq{<p>Source Title: <a href="$source->{url}">$source->{title}</a></p>\n};
		$html .= qq{<p>Source Twitter: };
		if ($source->{twitter}) {
			$html .= qq{<a href="https://twitter.com/#!/$source->{twitter}">$source->{twitter}</a></p>\n};
		} else {
			$html .= qq{NO twitter</p>\n};
		}
		$html .= qq{<p>Tags: $e->{tags}</p>\n};
		$html .= qq{<p>Author: $e->{author}</p>\n};
		$html .= qq{<p>Date: $e->{issued}</p>\n};
		$html .= qq{<hr>Redirector: $redirector\n};
		$html .= qq{<hr><p>Summary:<br>$e->{summary}</p>\n};

		my $twitter_status = $e->{title} . ($source->{twitter} ? " via \@$source->{twitter}" : '') . " $url";
		$html .= qq{<p><a href="http://twitter.com/home?status=$twitter_status">tweet</a></p>};
		$html .= qq{</body></html>\n};

		$self->_sendmail("Perl Feed: $e->{title}", { text => $text, html => $html } );
		$self->db->delete_from_queue('mail', $e->{id});
	}

	return;
}


sub _sendmail {
	my ($self, $subject, $content) = @_;

	main::LOG("Send Mail: $subject");

	my $config = $self->db->get_config_hash;
	my $msg = MIME::Lite->new(
		From    => ($config->{from} || 'dwimmer@dwimmer.org'),
		To      => 'szabgab@gmail.com',
		Subject => $subject,
		Type    => 'multipart/alternative',
	);
	my %type = (
		text => 'text/plain',
		html => 'text/html',
	);

	foreach my $t (qw(text html)) {
		my $att = MIME::Lite->new(
			Type     => 'text',
			Data     => $content->{$t},
			Encoding => 'quoted-printable',
		);
		$att->attr("content-type" => "$type{$t}; charset=UTF-8");
		$att->replace("X-Mailer" => "");
		$att->attr('mime-version' => '');
		$att->attr('Content-Disposition' => '');

		$msg->attach($att);
	}

	$msg->send;
}

1;


