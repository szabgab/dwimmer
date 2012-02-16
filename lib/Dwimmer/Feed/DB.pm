package Dwimmer::Feed::DB;
use Moose;

use Data::Dumper qw(Dumper);
use DateTime;
use DBI;

has 'store' => (is => 'ro', isa => 'Str', required => 1);
has 'dbh'   => (is => 'rw', isa => 'DBI::db');


sub connect {
	my ($self) = @_;

	if (not $self->dbh) {
		my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->store, "", "", {
			FetchHashKeyName => 'NAME_lc',
			RaiseError       => 1,
			PrintError       => 0,
		});
		$self->dbh( $dbh );
	}

	return $self->dbh;
}

sub add_source {
	my ($self, $e) = @_;
	
	$self->dbh->do('INSERT INTO sources (title, url, feed, comment, status) VALUES(?, ?, ?, ?, ?)',
		{},
		@$e{qw{title url feed comment status}});
}

sub get_all_entries {
	my ($self) = @_;
	my $sth = $self->dbh->prepare('SELECT * FROM entries ORDER BY issued DESC');
	$sth->execute;
	my @result;
	while (my $h = $sth->fetchrow_hashref) {
		push @result, $h;
	}

	return \@result;
}

sub find {
	my ($self, %args) = @_;

	my $ref = $self->dbh->selectrow_hashref('SELECT * FROM entries WHERE link LIKE ?', {}, $args{link});

	return $ref;
}

sub add {
	my ($self, %args) = @_;

	my @fields = grep {defined $args{$_}} qw(id source_id link author issued title summary content tags);
	my $f = join ',', @fields;
	my $p = join ',', (('?') x scalar @fields);

	my $issued = $args{issued};
	$args{issued} = $issued->ymd . ' ' . $issued->hms;

	my $sql = "INSERT INTO entries ($f) VALUES($p)";
	#main::LOG("SQL: $sql");
	$self->dbh->do($sql, {}, @args{@fields});
	my $id = $self->dbh->last_insert_id('', '', '', '');
	main::LOG("ID: $id");

	# only deliver new things
	my $NOT_TOO_OLD = 60*60*24;
	if ($issued->epoch > time - $NOT_TOO_OLD) {
		$self->dbh->do(q{INSERT INTO delivery_queue (channel, entry) VALUES ('mail', ?)}, {}, $id);
	}

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

sub get_sources {
	my ($self) = @_;
	
	my $sth = $self->dbh->prepare('SELECT * FROM sources WHERE status="enabled"');
	$sth->execute;
	my @r;
	while (my $h = $sth->fetchrow_hashref) {
		push @r, $h;
	}

	return \@r;
}

1;

