package Dwimmer::Feed::Sendmail;
use Moose;

our $VERSION = '0.32';

use Encode       ();
use LWP::UserAgent;
use MIME::Lite   ();
use Template;

use Dwimmer::Feed::Config;

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

	foreach my $entry (@$entries) {
		my ($source) = grep { $_->{id} eq $entry->{source_id} }  @$sources;

		# fix redirection and remove parts after path
		# This is temporarily here though it should be probably moved to the collector
		my $ua = LWP::UserAgent->new;
		my $t = Template->new();

		@{ $ua->requests_redirectable } = ();

		my $url = $entry->{link};
		my $response = $ua->get($url);

		my $status = $response->status_line;
		my %other;
		$other{status} = $status;
		if ( $response->code == 301 ) {
			$url = $response->header('Location');
			$other{redirected} = 1;
		}

		my $uri = URI->new($url);
		$uri->fragment(undef);
		$uri->query(undef);

		$url = $uri->canonical;
		$other{url} = $url;
		my $title = $entry->{title};
		#$title =~ s/&/
		# The hexa value from http://www.asciitable.com/
		$title =~ s/ +/%20/g;
		$title =~ s/!/%21/g;
		$title =~ s/"/%22/g;
		$title =~ s/#/%23/g;
		$title =~ s/'/%27/g;

		$other{twitter_status} = $title . ($source->{twitter} ? " via \@$source->{twitter}" : '') . " $url";

		my $site_id = $entry->{site_id};
		die "need site_id" if not defined $site_id;
		my $html_tt = Dwimmer::Feed::Config->get($self->db, $site_id, 'html_tt');
		$t->process(\$html_tt, {e => $entry, source => $source, other => \%other}, \my $html) or die $t->error;

		my $text_tt = Dwimmer::Feed::Config->get($self->db, $site_id, 'text_tt');
		$t->process(\$text_tt, $entry, \my $text) or die $t->error;

		my $subject_tt = Dwimmer::Feed::Config->get($self->db, $site_id, 'subject_tt');
		$t->process(\$subject_tt, $entry, \my $subject) or die $t->error;

		my $from = Dwimmer::Feed::Config->get($self->db, $site_id, 'from');

		next if not $self->_sendmail($from, $subject, { text => $text, html => $html } );

		$self->db->delete_from_queue('mail', $entry->{id});
	}

	return;
}


sub _sendmail {
	my ($self, $from, $subject, $content) = @_;

	main::LOG("Send Mail: $subject");

	if (not $from) {
		warn "from field is required. Cannot send mail.\n";
		return;
	}
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

	return if not $msg->send;
	return 1;
}

1;


