package DBIx::Skinny::Mixin::DBICTic;

use strict;
use warnings;
use UNIVERSAL::require;


our $VERSION = '0.01';


sub register_method {
    +{
        'resultset_dbictic' => \&resultset_dbictic,
    },
}


sub resultset_dbictic {
    my ( $self, $table, $where, $attr ) = @_;
    my $args = {};
    my $pkg  = 'DBIx::Skinny::SQL::DBICTic';

    if ( $self->dbd =~ m{DBD::(\w+)} ) {
        $pkg .= '::' . $1;
        $pkg->require;
    }

    $args->{ skinny }        = $self;
    $args->{ table }         = $table;
    $args->{ where_dbictic } = $where;
    $args->{ attr_dbictic }  = $attr;

    return $pkg->new( $args )->setup_dbictic;
}


1;
__END__

=pod

=head1 NAME

DBIx::Skinny::Mixin::DBICTic;

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
