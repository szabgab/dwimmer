package Dwimmer::DB::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Dwimmer::DB::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 sha1

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 fname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 lname

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 state

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 validation_key

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 verified

  data_type: 'bool'
  default_value: 0
  is_nullable: 1

=head2 register_ts

  data_type: 'integer defaul now'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "sha1",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "fname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "lname",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "state",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "validation_key",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "verified",
  { data_type => "bool", default_value => 0, is_nullable => 1 },
  "register_ts",
  { data_type => "integer defaul now", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head1 RELATIONS

=head2 sites

Type: has_many

Related object: L<Dwimmer::DB::Result::Site>

=cut

__PACKAGE__->has_many(
  "sites",
  "Dwimmer::DB::Result::Site",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 page_histories

Type: has_many

Related object: L<Dwimmer::DB::Result::PageHistory>

=cut

__PACKAGE__->has_many(
  "page_histories",
  "Dwimmer::DB::Result::PageHistory",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feed_collectors

Type: has_many

Related object: L<Dwimmer::DB::Result::FeedCollector>

=cut

__PACKAGE__->has_many(
  "feed_collectors",
  "Dwimmer::DB::Result::FeedCollector",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-06 11:19:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j5qscSMvjhfb+oQ1aSLLNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
