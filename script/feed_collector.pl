#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

#use LWP::Simple  qw(get);
use File::Slurp  qw(read_file write_file);
use JSON         qw(from_json to_json);
use XML::Feed;
use MIME::Lite;

my ($storage, $file) = @ARGV;
die "Usage: $0 ../storage.json  .../sources.json\n" if not $file;

my $data = {};
if (-e $storage) {
	$data = from_json scalar read_file $storage;
	#print keys %$data;
}
my $sources = from_json scalar read_file $file;
for my $chapter ( @{ $sources->{chapters} } ) {
	for my $e ( @{ $chapter->{entries} } ) {
		if ($e->{feed}) {
			LOG("Processing $e->{title}");
			my $feed = XML::Feed->parse(URI->new($e->{feed}));
			if (not $feed) {
				LOG("ERROR: " . XML::Feed->errstr);
				next;
			}
			if ($feed->title) {
				LOG("Title: " . $feed->title);
			} else {
				LOG("WARN: no title");
			}
			for my $entry ($feed->entries) {
				#print $entry, "\n";
				
				if (not $data->{$entry->link}) {
					my %current = (
						link    => $entry->link,
						title   => ($entry->title || ''),
						summary => ($entry->summary->body || ''),
						content => ($entry->content->body || ''),
					);
					$data->{$entry->link} = \%current;
					
					my $mail = '';
					$mail .= "$current{title}\n";
					$mail .= "$current{link}\n\n";
					$mail .= "$current{summary}\n\n";
					$mail .= "$current{content}\n\n------------------\n\n";
					sendmail("Feed: $current{title}", $mail);
				}
			}
		} else {
			warn "No feed for $e->{title}\n";
		}
	}
}
#print $mail;
#exit;
sub sendmail {
	my ($subject, $content) = @_;
	my $msg = MIME::Lite->new(
		From    => 'dwimmer@dwimmer.com',
		To      => 'szabgab@gmail.com',
		Subject => $subject,
		Data    => $content,
	);
	$msg->send;
}

write_file $storage, { binmode => ':utf8' }, to_json $data;

sub LOG {
	print "@_\n";
}

