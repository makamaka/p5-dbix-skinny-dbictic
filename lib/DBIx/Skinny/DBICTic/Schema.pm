package DBIx::Skinny::DBICTic::Schema;

use strict;
use warnings;

our $VERSION = '0.01';


sub import {
    my $caller = caller;

    my @functions = qw(
        relationship_info relationship has_one has_many belongs_to might_have  table condition
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

    $class->relationship_info->{ $base_table }->{ $name } = {
        base_table   => $base_table,
        %$args,
    };
}


#
# built-in
#

sub has_one ($$$) {
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


sub belongs_to ($$$) {
    my ( $name, $join_table, $condition ) = @_;
    relationship( $name, { table => $join_table, type => 'inner', condition => $condition }, caller );
}



1;
__END__

=pod

=head1 NAME

DBIx::Skinny::DBICTic::Schema;


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

=head1 SEE ALSO

L<DBIx::Skinny::DBICTic>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


