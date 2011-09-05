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

for my $e ( @{ $sources->{feeds}{entries} } ) {
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
					source  => $e->{feed},
					link    => $entry->link,
					author  => ($entry->{author} || ''),
					id      => ($entry->{id} || ''),
					issued  => $entry->issued->ymd . ' ' . $entry->issued->hms,
					title   => ($entry->title || ''),
					summary => ($entry->summary->body || ''),
					content => ($entry->content->body || ''),
					tags    => '', #$entry->tags,
				);
				$data->{$entry->link} = \%current;
				
				my $mail = '';
				$mail .= "$current{title}\n";
				$mail .= "Link: $current{link}\n\n";
				$mail .= "Source: $current{source}\n\n";
				$mail .= "Tags: $current{tags}\n\n";
				$mail .= "Author: $current{author}\n\n";
				$mail .= "Date: $current{issued}\n\n";
				$mail .= "Summary: $current{summary}\n\n";
				$mail .= "Content: $current{content}\n\n";
				$mail .= "-------------------------------\n\n";
				sendmail("Feed: $current{title}", $mail);
			}
		}
	} else {
		warn "No feed for $e->{title}\n";
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

write_file $storage, { binmode => ':utf8' }, to_json $data, {utf8 => 1, pretty => 1};

sub LOG {
	print "@_\n";
}

