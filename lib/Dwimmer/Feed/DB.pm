package Dwimmer::Feed::DB;
use Moose;

use Data::Dumper qw(Dumper);
use DBI;

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

CREATE TABLE delivery_queue (
	channel  VARCHAR(30) NOT NULL,
	entry    INTEGER     NOT NULL
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

	my $ref = $self->dbh->selectrow_hashref('SELECT * FROM entries WHERE link LIKE ?', {}, $args{link});

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
	my $id = $self->dbh->last_insert_id('', '', '', '');
	main::LOG("ID: $id");

	$self->dbh->do(q{INSERT INTO delivery_queue (channel, entry) VALUES ('mail', ?)}, {}, $id);

	return;
}

sub get_queue {
	my ($self, $channel) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM entries, delivery_queue WHERE entries.id=delivery_queue.entry AND channel = ?');
	$sth->execute($channel);
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}
	return \@results;
}

sub delete_from_queue {
	my ($self, $channel, $id) = @_;

	$self->dbh->do('DELETE FROM delivery_queue WHERE channel=? AND entry=?', {}, $channel, $id);

	return;
}


1;

