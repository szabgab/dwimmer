#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Encode       ();
use XML::Feed    ();
use MIME::Lite   ();
use DBI;


package Dwimmer::Collector::DB;
use Moose;

has 'store' => (is => 'ro', isa => 'Str', required => 1);
has 'dbh'   => (is => 'rw', isa => 'DBI::db');

my $SCHEMA = <<'SCHEMA';
CREATE TABLE entries (
	id        INTEGER PRIMARY KEY,
	source    VARCHAR(100),
	link      VARCHAR(100) UNIQUE NOT NULL,
	remote_id VARCHAR(100),
	author    VARCHAR(100),
	issued    VARCHAR(100),
	title     VARCHAR(100),
	summary   BLOB,
	content   BLOB,
	tags      VARCHAR(100)
);
SCHEMA

sub connect {
	my ($self) = @_;

	if (not $self->dbh) {
		my $need_create = not -e $self->store;

		my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->store, "", "", {
			FetchHashKeyName => 'NAME_lc',
			RaiseError       => 1,
			PrintError       => 0,
		});
		$self->dbh( $dbh );
		if ($need_create) {
			$dbh->do($SCHEMA);
		}
	}

	return $self->dbh;
}

sub find {
	my ($self, %args) = @_;

	my $ref = $self->dbh->selectrow_hashref('SELECT * FROM entries WHERE link = ?', {}, $args{link});

	return $ref;
}

sub add {
	my ($self, %args) = @_;

	my @fields = grep {defined $args{$_}} qw(id source link author issued title summary content tags);
	my $f = join ',', @fields;
	my $p = join ',', (('?') x scalar @fields);

	my $sql = "INSERT INTO entries ($f) VALUES($p)";
	#main::LOG("SQL: $sql");
	$self->dbh->do($sql, {}, @args{@fields});

	return;
}

1;


package Dwimmer::Collector;
use Moose;

use File::Slurp  qw(read_file);
use JSON         qw(from_json);

has 'sources' => (is => 'ro', isa => 'Str', required => 1);
has 'store'   => (is => 'ro', isa => 'Str', required => 1);
has 'db'      => (is => 'rw', isa => 'Dwimmer::Collector::DB');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Collector::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}

sub collect {
	my ($self) = @_;

	my $sources = from_json scalar read_file $self->sources;
	main::LOG("sources loaded");


	for my $e ( @{ $sources->{feeds}{entries} } ) {
		if (not $e->{feed}) {
			main::LOG("ERROR: No feed for $e->{title}");
			next;
		}
		eval {
			local $SIG{ALRM} = sub { die 'TIMEOUT' };
			alarm 10;

			main::LOG("Processing $e->{title}");
			my $feed = XML::Feed->parse(URI->new($e->{feed}));
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
					main::LOG("Adding $entry->{link}");
					$self->db->add(%current);
				}
			}
		};
		alarm(0);
		if ($@) {
			main::LOG("EXCEPTION $@");
		}
	}
}



1;

package main;

my ($storage, $source) = @ARGV;
die "Usage: $0 .../storage.db  .../sources.json\n" if not $source;

my $collector = Dwimmer::Collector->new(sources => $source, store => $storage);
$collector->collect();
exit;

sub LOG {
	print "@_\n";
}


__END__
my $data = {};
if (-e $storage) {
	$data = from_json scalar read_file $storage;
	#print keys %$data;
}
LOG("storage loaded");

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
				sendmail("Feed: $current{title}", $mail);
			}
		}

