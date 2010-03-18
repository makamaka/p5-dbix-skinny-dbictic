package DBIx::Skinny::SQL::DBICTic::OverwriteMethods;

use strict;
use warnings;

our $VERSION = '0.01';

# This module overwrites DBIx::Skinny::SQL methods.
# Don't inherit DBIx::Skinny::SQL.
#
# And assumed to followd by DBIx::Skinny::SQL ( or an inherited class ) and DBIx::Skinny::SQL::DBICTic.
#
# ex.)
#
# package DBIx::Skinny::SQL::DBICTic::FooBar;
# use base qw( DBIx::Skinny::SQL::OverwriteMethods DBIx::Skinny::SQL DBIx::Skinny::SQL::DBICTic );
# ....


sub retrieve {
    my ( $self ) = @_;
    my $pager = $self->_pager;

    return DBIx::Skinny::SQL::retrieve( $self ) unless $pager;

    my $itr = DBIx::Skinny::SQL::retrieve( $self );

    if ( wantarray ) {
        return $itr->all;
    }
    else {
        $itr->pager( $pager );
        return $itr;
    }
}


sub as_sql_where { # copied from original
    my $self = shift;

    if ( my $where = $self->where_used_by_sql_abstract ) {
        # この処理の結果、where_valuesは効かない
        my $sql = SQL::Abstract->new;
        my ( $statement, @bind ) = $sql->where( $where );
        @{ $self->bind } = @bind;
        return $statement;
    }

    $self->where && @{ $self->where } ?
        'WHERE ' . join(' AND ', @{ $self->where }) . "\n" :
        '';
}


sub as_sql_having { # copied from original
    my $self = shift;

    if ( my $having = $self->having_used_by_sql_abstract ) {
        my $sql = SQL::Abstract->new;
        my ( $statement, @bind ) = $sql->where( $having );
        @{ $self->bind } = @bind;
        $statement =~ s{^\s*WHERE}{HAVING};
        return $statement;
    }

    $self->having && @{ $self->having } ?
        'HAVING ' . join(' AND ', @{ $self->having }) . "\n" :
        '';
}


1;
__END__

=pod

=head1 NAME

DBIx::Skinny::SQL::DBICTic::OverwriteMethods

=head1 SYNOPSIS

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

