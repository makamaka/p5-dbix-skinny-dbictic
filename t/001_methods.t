use lib './t';
use Test::More;
use strict;
use warnings;


BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
    use_ok( 'Mock::SQLite' );
}

my $skinny = Mock::SQLite->new;

can_ok( $skinny, 'resultset_dbictic' );

my $rs = $skinny->resultset_dbictic( 'users' );

can_ok( $rs, 'retrieve' );
isa_ok( $rs, 'DBIx::Skinny::SQL::DBICTic' );

done_testing();

