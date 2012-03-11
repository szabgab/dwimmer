package Dwimmer::Feed::DB;
use Moose;

use Carp ();
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

	my @fields = qw(title url feed comment status twitter);
	my $fields = join ', ', @fields;
	my $placeholders = join ', ', (('?') x scalar @fields);
	$self->dbh->do("INSERT INTO sources ($fields) VALUES($placeholders)",
		{},
		@$e{@fields});
	return $self->dbh->last_insert_id('', '', '', '');
}

sub get_all_entries {
	my ($self) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM entries ORDER BY issued DESC');
	$sth->execute;
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}

	return \@results;
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
	main::LOG("   ID: $id");

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
	my ( $self, %opt ) = @_;

	my $sql = 'SELECT * FROM sources';
	if ($opt{enabled}) {
		$sql .= ' WHERE status="enabled"';
	}
	my $sth = $self->dbh->prepare($sql);
	$sth->execute;
	my @r;
	while (my $h = $sth->fetchrow_hashref) {
		push @r, $h;
	}

	return \@r;
}

sub get_source_by_id {
	my ( $self, $id ) = @_;

	my $sources = $self->get_sources;
	my ($s) = grep { $_->{id} eq $id }  @$sources;
	return $s;
}


sub able {
	my ($self, $id, $able) = @_;
	$able = $able ? 'enabled' : 'disabled';
	my $sql = qq{UPDATE sources SET status = "$able" WHERE id=?};
	$self->dbh->do($sql, undef, $id);
}
sub update {
	my ($self, $id, $field, $value) = @_;

	Carp::croak("Invalid field '$field'")
		if $field !~ m{^(feed|comment|twitter)$};

	my $sql = qq{UPDATE sources SET $field = ? WHERE id=?};
	$self->dbh->do($sql, undef, $value, $id);
}

sub set_config {
	my ($self, $key, $value) = @_;
	$self->delete_config($key);
	$self->dbh->do('INSERT INTO config (key, value) VALUES (?, ?)', undef, $key, $value);
	return;
}
sub delete_config {
	my ($self, $key) = @_;
	$self->dbh->do('DELETE FROM config WHERE key=?', undef, $key);
	return;
}

sub get_config {
	my ($self) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM config ORDER BY key DESC');
	$sth->execute;
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}

	return \@results;
}

1;

