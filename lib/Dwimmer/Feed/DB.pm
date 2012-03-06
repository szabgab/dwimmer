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

	$self->dbh->do('INSERT INTO sources (title, url, feed, comment, status) VALUES(?, ?, ?, ?, ?)',
		{},
		@$e{qw{title url feed comment status}});
	return $self->dbh->last_insert_id('', '', '', '');
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
		if $field ne 'feed' and $field ne 'comment';

	my $sql = qq{UPDATE sources SET $field = ? WHERE id=?};
	$self->dbh->do($sql, undef, $value, $id);
}

1;

