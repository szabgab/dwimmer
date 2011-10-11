package Dwimmer::DB::Result::SiteConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Dwimmer::DB::Result::SiteConfig

=cut

__PACKAGE__->table("site_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 siteid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "siteid",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-11 10:24:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y8WzyigjG3r6sy3kdyWHwg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
