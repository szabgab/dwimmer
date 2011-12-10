package Dwimmer::Feed::Sendmail;
use Moose;

use Encode       ();
use MIME::Lite   ();


sub sendmail {
	my ($subject, $content) = @_;
	my %current;
	my $mail = '';
	$mail .= "$current{title}\n";
	$mail .= "Link: $current{link}\n\n";
	$mail .= "Source: $current{source}\n\n";
	$mail .= "Tags: $current{tags}\n\n";
	$mail .= "Author: $current{author}\n\n";
	$mail .= "Date: $current{issued}\n\n";
	$mail .= "Summary:\n$current{summary}\n\n";
	$mail .=  Encode::encode('UTF-8', "Content:\n$current{content}\n\n");
	$mail .= "-------------------------------\n\n";
	#sendmail("Feed: $current{title}", $mail);


	my $msg = MIME::Lite->new(
		From    => 'dwimmer@dwimmer.com',
		To      => 'szabgab@gmail.com',
		Subject => $subject,
		Data    => $content,
	);
	$msg->send;
}

1;


