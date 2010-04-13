use lib './t';
use Test::More;
use strict;
use warnings;
use Data::Dumper;


BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

use Mock::SQLite;
use Mock::Pg;
use Mock::MySQL;

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


subtest 'having, group_by, +select' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            '+select'  => [ 'count(has_books.id)' ],
            '+as'      => [ 'book_num' ],
            'join'     => [ qw/ has_books / ],
            'group_by' => [ qw/ users.id / ],
            'order_by' => 'users.id ASC',
            'having'   => 'book_num <= 3', # sqlite can't deal with bind param for having
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 2, 'group_by, having book_num  <= 3' );

    my $user = $itr->next;

    is( $user->book_num, 3 );

    done_testing;
};


subtest 'For Pg: having, group_by, +select' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    Mock::Pg->connect({dsn => $dsn, username => $username, password => $password});
    Mock::Pg->setup_test_db;

    $skinny = Mock::Pg->new;

    isa_ok( $skinny, 'Mock::Pg' );

    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            '+select'  => [ 'count(has_books.id)' ],
            '+as'      => [ 'book_num' ],
            'join'     => [ qw/ has_books / ],
            'group_by' => [ qw/ users.id users.name / ],  # need users.name
            'order_by' => 'users.id ASC',
            'having'   => { 'book_num' => { '<=' => 3 } },
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 2, 'group_by, having book_num  <= 3' );

    my $user = $itr->next;

    is( $user->book_num, 3 );

    done_testing;
};


subtest 'For Pg: having only' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    isa_ok( $skinny, 'Mock::Pg' );

    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            'select'  => [ q/ 'count(id ) = max(id)' / ],
            'as'      => [ 'is_equal' ],
            'having'   => 'count(id ) = max(id)',
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 1, 'having count(id ) = max(id)' );

    my $user = $itr->next;

    is( $user->is_equal, 'count(id ) = max(id)' );

    done_testing;
};


subtest 'For mysql: having, group_by, +select' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    Mock::MySQL->connect({dsn => $dsn, username => $username, password => $password});
    Mock::MySQL->setup_test_db;

    $skinny = Mock::MySQL->new;
    isa_ok( $skinny, 'Mock::MySQL' );

    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            '+select'  => [ 'count(has_books.id)' ],
            '+as'      => [ 'book_num' ],
            'join'     => [ qw/ has_books / ],
            'group_by' => [ qw/ users.id / ],
            'order_by' => 'users.id ASC',
            'having'   => { 'book_num' => { '<=' => 3 } },
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 2, 'group_by, having book_num  <= 3' );

    my $user = $itr->next;

    is( $user->book_num, 3 );

    done_testing;
};


subtest 'For mysql: having only' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    isa_ok( $skinny, 'Mock::MySQL' );

    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            'select'  => [ q/ 'count(id ) = max(id)' / ],
            'as'      => [ 'is_equal' ],
            'having'   => 'count(id ) = max(id)',
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 1, 'having count(id ) = max(id)' );

    my $user = $itr->next;

    is( $user->is_equal, 'count(id ) = max(id)' );

    done_testing;
};

done_testing();

