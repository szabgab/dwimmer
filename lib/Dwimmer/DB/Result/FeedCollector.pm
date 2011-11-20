package Dwimmer::DB::Result::FeedCollector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Dwimmer::DB::Result::FeedCollector

=cut

__PACKAGE__->table("feed_collector");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 owner

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_ts

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
	"id",
	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"name",
	{ data_type => "varchar", is_nullable => 0, size => 100 },
	"owner",
	{ data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
	"created_ts",
	{ data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint( "name_unique", ["name"] );

=head1 RELATIONS

=head2 owner

Type: belongs_to

Related object: L<Dwimmer::DB::Result::User>

=cut

__PACKAGE__->belongs_to(
	"owner",
	"Dwimmer::DB::Result::User",
	{ id            => "owner" },
	{ is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 feeds

Type: has_many

Related object: L<Dwimmer::DB::Result::Feed>

=cut

__PACKAGE__->has_many(
	"feeds",
	"Dwimmer::DB::Result::Feed",
	{ "foreign.collector" => "self.id" },
	{ cascade_copy        => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-06 11:19:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oyLRH/JADu4Bog21UHx2yQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
