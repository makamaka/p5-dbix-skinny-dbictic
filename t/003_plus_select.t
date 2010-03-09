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


subtest 'non where - attribute +select' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            '+select' => [ qw/foobar/ ], # this is meaningless but enough.
        },
    );

    like( $rs->as_sql, qr/\Wfoobar\W/ ); # SELECT users.id, users.name, foobar FROM users

    done_testing;
};


subtest 'non where - attribute +select, +as' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            '+select' => [ qw/count(*)/ ], # this is meaningless but enough.
            '+as'     => [ qw/count/ ],
        },
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'id' );
    can_ok( $user, 'name' );
    can_ok( $user, 'count' );


    is( $user->count, 4 );

    done_testing;
};


done_testing();

