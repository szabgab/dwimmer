package Dwimmer::Feed::Sendmail;
use Moose;

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

	foreach my $e (@$entries) {
		my $text = '';
		$text .= "Title: $e->{title}\n";
		$text .= "Link: $e->{link}\n\n";
		$text .= "Source: $e->{source}\n\n";
		$text .= "Tags: $e->{tags}\n\n";
		$text .= "Author: $e->{author}\n\n";
		$text .= "Date: $e->{issued}\n\n";
		$text .= "Summary:\n$e->{summary}\n\n";
		#$text .=  Encode::encode('UTF-8', "Content:\n$e->{content}\n\n");
		#$text .= "-------------------------------\n\n";

		my $html = qq{<html><head><title></title></head><body>\n};
		$html .= qq{<h1><a href="$e->{link}">$e->{title}</a></h1>\n};
		$html .= qq{<p>Link: $e->{link}</p>\n};
		$html .= qq{<p>Source: $e->{source}</p>\n};
		$html .= qq{<p>Tags: $e->{tags}</p>\n};
		$html .= qq{<p>Author: $e->{author}</p>\n};
		$html .= qq{<p>Date: $e->{issued}</p>\n};
		$html .= qq{<hr><p>Summary:<br>$e->{summary}</p>\n};

		$html .= qq{<p><a href="http://twitter.com/home?status=$e->{title} $e->{link}">tweet</a></p>};
		$html .= qq{</body></html>\n};

		_sendmail("Perl Feed: $e->{title}", { text => $text, html => $html } );
		$self->db->delete_from_queue('mail', $e->{id});
	}

	return;
}


sub _sendmail {
	my ($subject, $content) = @_;

	main::LOG("Send Mail: $subject");

	my $msg = MIME::Lite->new(
		From    => 'dwimmer@dwimmer.com',
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


