package DBIx::Skinny::SQL::DBICTic;

use strict;
use warnings;

# This module requires the below methods
#  - skinny, add_join, add_select, order, limit, offset, group, add_having, add_where
# And assumed to call with DBIx::Skinny::SQL::OverwriteMethods and DBIx::Skinny::SQL( or an inherited class )
#    before this module is used.
#
# ex.)
#
# package DBIx::Skinny::SQL::DBICTic::FooBar;
# use base qw( DBIx::Skinny::SQL::OverwriteMethods DBIx::Skinny::SQL DBIx::Skinny::SQL::DBICTic );
# ....

use Data::Page;
use SQL::Abstract;
use DBIx::Skinny::Accessor;

use Data::Dumper;

mk_accessors(
    qw/ table where_dbictic attr_dbictic where_used_by_sql_abstract having_used_by_sql_abstract /
);

our $VERSION = '0.01';


my $DefaultCountSubref = sub {
    my $str = $_[0];
    $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT COUNT(*) FROM}i;
    return ( $str, 'COUNT(*)' );
};

#
# Public API
#

sub relationship2table {
    my ( $self, $name, $table ) = @_;
    $self->{ _relationship2table }->{ $name } = $table if ( @_ > 2 );
    $self->{ _relationship2table }->{ $name };
}


sub setup_dbictic {
    my ( $self, $args ) = @_;
    my $skinny = $self->skinny;
    my $table  = $self->table;
    my $where  = $self->where_dbictic;
    my $attr   = $self->attr_dbictic;

    $self->_make_join()
         ->_make_select() # must be called after _make_join
         ->_make_group_and_order()
         ->_make_where_closure()
}


#
# Private
#

sub _make_join {
    my ( $self ) = @_;
    my $attr = $self->attr_dbictic;

    return $self->from( [ $self->table ] ) && $self unless ( $attr->{ 'join' } );

    $self->from( [] );

    my $rels = $self->skinny->schema->relationship_info->{ $self->table } || {};

    local $Carp::CarpLevel = 1;

    for my $name ( @{ $attr->{ join } } ) {
        my $rel = $rels->{ $name } or Carp::croak("No such a join name '$name'.");
        my $val = {
            condition => $rel->{ condition },
            type      => $rel->{ type },
            table     => $rel->{ table },
        };
        $self->add_join( $rel->{ base_table } => $val );
        $self->relationship2table( $name => $rel->{ table } );
    }

    $self;
}


sub _make_select {
    my ( $self ) = @_;
    my $table = $self->table;
    my $attr  = $self->attr_dbictic;

    local $Carp::CarpLevel = 1;

    if ( not exists $attr->{ 'select' } ) {
        my $schema = $self->skinny->schema->schema_info->{ $table };
        my $prefix = exists $attr->{ 'me_alias' } ? $attr->{ 'me_alias' } . '.' : "$table.";
        @{ $attr->{ 'select' } } = map { $prefix . $_ } @{ $schema->{ columns } };
        @{ $attr->{ 'as' }  }    = @{ $schema->{ columns } };
    }

    if ( exists $attr->{ '+select' } ) {
        push @{ $attr->{ 'select' } }, @{ $attr->{ '+select' } };
        if ( exists $attr->{ '+as' } ) {
            push @{ $attr->{ 'as' } }, @{ $attr->{ '+as' } };
        }
        else {
            push @{ $attr->{ 'as' } }, @{ $attr->{ '+select' } };
        }
    }

    unless ( @{ $attr->{ 'select' } } == @{ $attr->{ 'as' } } ) {
        Carp::croak("'select' number and 'as' number are mismatched.");
    }

    for my $i ( 0 .. $#{ $attr->{ 'select' } } ) {
        my $col = $attr->{ 'select' }->[ $i ];

        $col =~ s{^(\w+)}{ $self->relationship2table( $1 ) || $1; }e;

        my $as  = $attr->{ 'as' }->[ $i ];
        $self->add_select( $col => $as );
    }

    $self;
}


sub _make_group_and_order {
    my ( $self ) = @_;
    my $attr  = $self->attr_dbictic;

    $self->order( { column => $attr->{ order_by } } ) if ( exists $attr->{ order_by } );
    $self->offset( $attr->{ offset } ) if ( exists $attr->{ offset } );
    $self->limit( $attr->{ limit } )   if ( exists $attr->{ limit } );
    $self->group( [ map { { column => $_ } } @{ $attr->{ group_by } } ] ) if ( exists $attr->{ group_by } );

    my $having = $attr->{ having };

    if ( $attr->{ use_sql_abstract } ) {
        $self->having_used_by_sql_abstract( $having );
    }
    elsif ( $having and ref( $having ) eq 'HASH' ) {
        for my $k ( keys %$having ) {
            $self->add_having( $k => $having->{ $k } );
        }
    }
    elsif ( $having and ref( $having ) eq 'ARRAY' ) {
        $self->add_having( @$having );
    }

    $self;
}


sub _make_where_closure {
    my ( $self ) = @_;
    my $attr  = $self->attr_dbictic;
    my $where = $self->where_dbictic;

    if ( $attr->{ use_sql_abstract } ) {
        $self->where_used_by_sql_abstract( $where );
    }
    elsif ( $where and ref( $where ) eq 'HASH' ) {
        for my $k ( keys %$where ) {
            $self->add_where( $k => $where->{ $k } );
        }
    }
    elsif ( $where and ref( $where ) eq 'ARRAY' ) {
        $self->add_where( @$where );
    }

    $self;
}


sub _pager {
    my ( $self ) = @_;
    my $attr = $self->attr_dbictic;
    my $rows = $attr->{ rows };
    my $page = $attr->{ page };

    return unless ( $page and $rows );

    my $count_subref = $attr->{ count_subref };

    if ( $attr->{ group_by } and not $count_subref ) {
        $count_subref = sub {
            my $str = $_[0];
            my $column =  sprintf( 'COUNT(DISTINCT(%s))', join( ',', @{ $attr->{ group_by } } ) );
            $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT $column FROM}i;
            $str =~ s{GROUP\s+BY\s+(?:[.\w]+,?\s*){1,}}{}i;
            return ( $str, $column );
        };
    }

    my ( $sql, $count_col ) = ( $count_subref || $DefaultCountSubref )->( $self->as_sql );

    my $total  = $self->skinny->search_by_sql( $sql, $self->bind )->first->get_column( lc $count_col );
    my $pager  = Data::Page->new();
    my $offset = $rows * ( $page - 1 );

    $pager->entries_per_page( $rows );
    $pager->current_page( $page );
    $pager->total_entries( $total );

    $self->limit( $rows );
    $self->offset( $offset );

    return $pager;
}


#
# DBIx::Skinny::Iterator
#

sub DBIx::Skinny::Iterator::pager {
    $_[0]->{ _pager } = $_[1] if @_ > 1;
    $_[0]->{ _pager };
}


1;
__END__

=pod

=head1 NAME

DBIx::Skinny::SQL::DBICTic

=head1 SYNOPSIS

=head1 METHODS

=head2 relationship2table

=head2 setup_dbictic

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
