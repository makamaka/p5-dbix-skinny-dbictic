package DBIx::Skinny::DBICTic;

use strict;
use warnings;

our $VERSION = '0.01';

1;
__END__

=pod

=encoding utf8

=head1 NAME

DBIx::Skinny::DBICTic - dbic-like interface

=head1 SYNOPSIS

    package Your::Model::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::DBICTic::Schema;
    
    install_table 'user' => schema {
        pk 'id';
        columns qw/
            id name
        /;
        
        # built-in relationship
        has_many 'profiles'
                    => 'user_profile' => 'user.id = user_profile.user_id';
        might_have 'status'
                    => 'user_status'  => 'user.id = user_status.user_id';
        
        # 
        relationship 'a_relation'
                    => 'user_status' => {
                        condition => 'user.id user_status.user_id',
                        type => 'inner',
                    };
    };
    
    install_table 'user_profile' => schema {
        pk 'id';
        columns qw/
            id user_id name value
        /;
    };
    
    install_table 'user_status' => schema {
        pk 'user_id';
        columns qw/
            user_id status
        /;
    };
    
    
    package Your::Model;
    
    use DBIx::Skinny setup => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    
    use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];
    
    
    package main;
    
    my $skinny = Your::Model->new;
    
    my $rs = $skinny->resultset_dbictic( 'user',
        { 'user.id' => 1 },
        {
            'join'    => [ 'profiles' ],
            '+select' => [ qw( profiles.name profiles.value ) ],
            '+as'     => [ qw( prof_name prof_value ) ],
        }
    );
    
    my $itr = $rs->retrieve;
    
    $rs = $skinny->resultset_dbictic( 'user',
        undef,
        {
            order_by => 'id DESC',
            page     => 1,
            rows     => 10,
        }
    );
    
    $itr = $rs->retrieve;
    
    my $pager = $itr->pager;

=head1 DESCRIPTION

DBIx::Class-like features for DBIx::Skinny

=head1 SCHEMA FEATURE

In your schema class, you can use below functions.

=head2 relationship

  relationship $join_name, { table => $table, condition => $cond, type => $type };

C<$join_name> is used by C<resultset_dbictic>'s  join attribute.
C<$table> is a joining table name.
C<$cond> is a condition and $type is a join type.
See L<DBIx::Skinny::Resultset>.

for example:

    install_table 'some_table' => schema {
        pk 'id';
        columns qw/id name /;
        relationship 'a_relation'
                    => 'other_table' => {
                        condition => 'some_table.id = other_table.id',
                        type => 'inner',
                    };
    };


=head2 has_one

  has_one $join_name, $table, $condtion;

A wrapper of C<relationship>.
C<$join_name> is used by C<resultset_dbictic>'s  join attribute.
C<$table> is a joining table name.
C<$cond> is a condition.

for example:

    install_table 'some_table' => schema {
        pk 'id';
        columns qw/id name /;
        has_one 'has_one_relation' => 'other_table' => 'some_table.id = other_table.id';
    };


=head2 might_have

  might_have $join_name, $table, $condtion;

A wrapper of C<relationship>.
C<$join_name> is used by C<resultset_dbictic>'s  join attribute.
C<$table> is a joining table name.
C<$cond> is a condition.

for example:

    install_table 'some_table' => schema {
        pk 'id';
        columns qw/id name /;
        might_have 'might_have_relation' => 'other_table' => 'some_table.id = other_table.id';
    };

=head2 has_many

  has_many $join_name, $table, $condtion;

A wrapper of C<relationship>.
C<$join_name> is used by C<resultset_dbictic>'s  join attribute.
C<$table> is a joining table name.
C<$cond> is a condition.

for example:

    install_table 'some_table' => schema {
        pk 'id';
        columns qw/id name /;
        has_many 'has_many_relation' => 'other_table' => 'some_table.id = other_table.id';
    };

=head2 belongs_to

  belongs_to $join_name, $table, $condtion;

A wrapper of C<relationship>.
C<$join_name> is used by C<resultset_dbictic>'s  join attribute.
C<$table> is a joining table name.
C<$cond> is a condition.

for example:

    install_table 'some_table' => schema {
        pk 'id';
        columns qw/id name /;
        has_one 'belongs_to_relation' => 'other_table' => 'some_table.id = other_table.id';
    };


=head1 SKINNY METHOD

In your model class, you can call C<DBICTic> as mixin module.

    package Your::Model;
    use DBIx::Skinny;
    use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];

=head2 resultset_dbictic

  $rs = $skinny->resultset_dbictic( $table, $where, $attr );

L<DBIx::Class::Resultset>-like interface.
C<$table> is a table you need. C<$where> is a condition.
If you set C<use_sql_abstract>, the C<$where> is applied to L<SQL::Abstract>.
C<$attr> is attributes.
See L</RESULTSET ATTRIBUTES> for available attributes.

It returns L<DBIx::Skiny::SQL::DBICTic> object which inherits L<DBIx::Skiny::SQL>.

If C<page> and C<rows> are specified, an iterator returned by C<$rs> has
C<pager> method. it returns L<Data::Page> object.

  $rs  = $skinny->resultset_dbictic( $table, {}, { page => 2, rows => 10 } );
  $itr = $rs->retrieve.
  $pager = $itr->pager; # Data::Page object


=head1 RESULTSET ATTRIBUTES

=head2 join

  join => $listref

Names specified by relationship (or its wrapper) in your schema class.

It can accept nested join relations.

  'join' => [ { 'book' => 'author' } ]

=head2 select

  select => $listref

Column names want to select.

  'select' => [ 'user_id', 'user_name' ],

=head2 as

  as => $listref

Alias names of columns specified by C<select>.

  'as' => [ 'id', 'name' ],

=head2 +select

  +select => $listref

Adding column names.

  '+select' => [ 'author.name' ],

=head2 +as

  +as => $listref

Alias names of columns specified by C<+select>.

  '+as' => [ 'author_name' ],

=head2 order_by

  order_by => $scalar

order by clause.

  'order_by' => 'id DESC'

=head2 limit

  limit => $number

limit number.

=head2 page

  page => $number

A page number. it must be used with C<rows> attributes.

=head2 rows

  rows => $number

A number in one page.

=head2 group_by

  group_by => $listref

group by clause.

  group_by => [ 'id' ],

=head2 having

  having => $hashref
  having => $arrayref

having clause.

=head2 count_subref

  count_subref => sub {
      my $sql = shift;
      return ( $str, $column );
  }

A subroutine reference which returns a SQL statement and a column when C<page> and C<rows>
attributes is set.

This subroutine takes a SQL statement (returned by as_sql) and must return
a SQL statement for count and its count column.

Default by:

    sub {
        my $str = $_[0];
        $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT COUNT(*) FROM}i;
        return ( $str, 'COUNT(*)' );
    };

If using group_by attribute:

    sub {
        my $str = $_[0];
        my $column =  sprintf( 'COUNT(DISTINCT(%s))', join( ',', @{ $attr->{ group_by } } ) );
        $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT $column FROM}i;
        $str =~ s{GROUP\s+BY\s+(?:[.\w]+,?\s*){1,}}{}i;
        return ( $str, $column );
    };

For example;

    'count_subref' => sub {
        my $sql = $_[0];
        sprintf( 'SELECT count(*) AS count_num FROM ( %s ) AS subquery', $sql ), 'count_num';
    }

This counter subroutine will be called when the resultset object use C<retrieve> method.


=head2 use_sql_abstract

  use_sql_abstract => $bool

If set ture, C<$where> and C<having> are applied to L<SQL::Abstract>.

=head1 SEE ALSO

L<DBIx::Skinny>,
L<DBIx::Class::Resultset>,
L<SQL::Abstract>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
