package Dwimmer::Feed::Error;

our $VERSION = '0.32';
use MIME::Lite   ();

sub send_error {
    my ($feed, $content) = @_;

    my $subjec = "Error in feed collection for $feed";

    my $from = 'gabor@szabgab.com';

	my $msg = MIME::Lite->new(
		From    => $from,
		To      => 'szabgab@gmail.com',
		Subject => $subject,
		Type    => 'multipart/alternative',
	);
	my %type = (
		text => 'text/plain',
		html => 'text/html',
	);

	my $att = MIME::Lite->new(
		Type     => 'text',
		Data     => $content,
		Encoding => 'quoted-printable',
	);
	$att->attr("content-type" => "text; charset=UTF-8");
	$att->replace("X-Mailer" => "");
	$att->attr('mime-version' => '');
	$att->attr('Content-Disposition' => '');

	$msg->attach($att);

	$msg->send;
}

1;


