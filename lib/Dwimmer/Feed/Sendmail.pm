package Dwimmer::Feed::Sendmail;
use Moose;

use Encode       ();
use MIME::Lite   ();

has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}


sub send {
	my ($self) = @_;

	my @entries = $self->db->search( email => 'NULL' );

	foreach my $e (@entries) {
		my $mail = '';
		$mail .= "$e->{title}\n";
		$mail .= "Link: $e->{link}\n\n";
		$mail .= "Source: $e->{source}\n\n";
		$mail .= "Tags: $e->{tags}\n\n";
		$mail .= "Author: $e->{author}\n\n";
		$mail .= "Date: $e->{issued}\n\n";
		$mail .= "Summary:\n$e->{summary}\n\n";
		$mail .=  Encode::encode('UTF-8', "Content:\n$e->{content}\n\n");
		$mail .= "-------------------------------\n\n";

		#_sendmail("Perl Feed: $current{title}", $mail);
	}

	return;
}


sub _sendmail {
	my ($subject, $content) = @_;

	my $msg = MIME::Lite->new(
		From    => 'dwimmer@dwimmer.com',
		To      => 'szabgab@gmail.com',
		Subject => $subject,
		Data    => $content,
	);
	$msg->send;
}

1;


