package DBIx::Skinny::Mixin::SomethingDBICTic;

use strict;
use warnings;

use DBIx::Skinny::SQL::SomethingDBICTic;

our $VERSION = '0.01';


sub register_method {
    +{
        'resultset_dbictic' => \&resultset_dbictic,
    },
}


sub resultset_dbictic {
    my ( $self, $table, $where, $attr ) = @_;
    my $args = {};

    #my $query_builder_class = $class->dbd->query_builder_class; # inmutable!

    $args->{ skinny }        = $self;
    $args->{ table }         = $table;
    $args->{ where_dbictic } = $where;
    $args->{ attr_dbictic }  = $attr;

    return DBIx::Skinny::SQL::SomethingDBICTic->new( $args )->setup_dbictic;
}


1;
__END__
