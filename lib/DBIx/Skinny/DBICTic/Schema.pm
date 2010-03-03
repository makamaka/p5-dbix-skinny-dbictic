package DBIx::Skinny::DBICTic::Schema;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.01';


sub import {
    my $caller = caller;

    my @functions = qw(
        relationship_info add_relation relationship has_a has_many belongs_to might_have  table condition
    );

    no strict 'refs';
    for my $func (@functions) {
        *{"$caller\::$func"} = \&$func;
    }
}


sub relationship_info { $_[0]->schema_info->{ _relationship } ||= {}; }


sub relationship ($$;$) {
    my ( $name, $args, $class ) = @_;

    $class ||= caller;

    my $base_table = $class->schema_info->{ _installing_table };

# いらないか
#    unless ( $base_table =~ /[\s.]/ ) { # aliasとしてmeをつける
#        $base_table .= ' AS me';
#    }
#    my $join_table = $args->{ table };
#    unless ( $join_table =~ /[\s.]/ ) { # テーブル名のみならaliasとしてrelationship nameをつける
#        $join_table .= ' AS ' . $name;
#    }

    $class->relationship_info->{ $base_table }->{ $name } = {
        base_table   => $base_table,
        %$args,
    };
}


#
# builtin
#

sub has_one ($) {
    my ( $name, $join_table, $condition ) = @_;
    relationship( $name, { table => $join_table, type => 'inner', condition => $condition }, caller );
}


sub might_have ($$$) {
    my ( $name, $join_table, $condition ) = @_;
    relationship( $name, { table => $join_table, type => 'left', condition => $condition }, caller );
}


sub has_many ($$$) {
    my ( $name, $join_table, $condition ) = @_;
    relationship( $name, { table => $join_table, type => 'left', condition => $condition }, caller );
}


sub belongs_to ($) {
    my ( $name, $join_table, $condition ) = @_;
    relationship( $name, { table => $join_table, type => 'inner', condition => $condition }, caller );
}



1;
__END__



