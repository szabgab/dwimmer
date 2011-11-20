package Dwimmer::DB::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Dwimmer::DB::Result::Page

=cut

__PACKAGE__->table("page");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 revision

  data_type: 'integer'
  is_nullable: 0

=head2 siteid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 filename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 redirect

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
	"id",
	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"revision",
	{ data_type => "integer", is_nullable => 0 },
	"siteid",
	{ data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
	"filename",
	{ data_type => "varchar", is_nullable => 0, size => 255 },
	"redirect",
	{ data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 siteid

Type: belongs_to

Related object: L<Dwimmer::DB::Result::Site>

=cut

__PACKAGE__->belongs_to(
	"siteid",
	"Dwimmer::DB::Result::Site",
	{ id            => "siteid" },
	{ is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 page_histories

Type: has_many

Related object: L<Dwimmer::DB::Result::PageHistory>

=cut

__PACKAGE__->has_many(
	"page_histories",
	"Dwimmer::DB::Result::PageHistory",
	{ "foreign.pageid" => "self.id" },
	{ cascade_copy     => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-08-28 13:00:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjjL/uh0wwbqAQ71lz+ByQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->has_one(
	'details',
	"Dwimmer::DB::Result::PageHistory",
	{ "foreign.pageid" => "self.id", "foreign.revision" => "self.revision" },
	{ cascade_copy     => 0,         cascade_delete     => 0 },
);

1;
