use lib './t';
use Test::More;
use strict;
use warnings;


BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
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


subtest 'non where - non attribute' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},  {},
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'id' );
    can_ok( $user, 'name' );

    done_testing;
};


subtest 'non where - attribute select' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        { 'select' => [ qw/ id / ] },
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'id' );

    ok( not eval q{ $user->name } );

    done_testing;
};


subtest 'non where - attribute select, as' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'select' => [ qw/ id / ],
            'as'     => [ qw/ foobar / ],
        },
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'foobar' );

    ok( not eval q{ $user->id } );

    done_testing;
};


subtest 'non where - attribute as only' => sub {
    $rs = eval { $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'as'     => [ qw/ foobar hoge / ],
        },
    ) };

    like( $@, qr/'as' is set but 'select' is not set/ );


    done_testing;
};


done_testing();

