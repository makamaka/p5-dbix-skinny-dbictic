use lib './t';
use Test::More;
use strict;
use warnings;


BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
#    plan skip_all => "TODO";
}

use Mock::SQLite;

my $skinny = Mock::SQLite->new;
my ( $itr, $rs );

subtest 'check base data' => sub {
    $skinny->setup_test_db;

    is( $skinny->search( 'users' )->count, 4, 'users' );
    is( $skinny->search( 'authors' )->count, 4, 'authors' );
    is( $skinny->search( 'books' )->count, 6, 'books' );
    is( $skinny->search( 'user_book' )->count, 11, 'user_book' );

    done_testing;
};


subtest 'limit' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'limit' => 2,
        },
    );

    is( $rs->retrieve->count, 2 );

    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'limit' => 0,
        },
    );

    is( $rs->retrieve->count, 4 );

    done_testing;
};



subtest 'limit, offset' => sub {
    $itr = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'order_by' => 'id ASC',
            'limit'  => 2, 
        },
    )->retrieve;

    is( join( ',', map { $_->id } $itr->all ), '1,2' );

    $itr = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'order_by' => 'id ASC',
            'limit'  => 2, 
            'offset' => 1,
        },
    )->retrieve;

    is( join( ',', map { $_->id } $itr->all ), '2,3' );

    $itr = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'order_by' => 'id ASC',
            'limit'  => 2, 
            'offset' => 2,
        },
    )->retrieve;

    is( join( ',', map { $_->id } $itr->all ), '3,4' );

    done_testing;
};


done_testing();

