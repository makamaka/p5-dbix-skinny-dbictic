use lib './t';
use Test::More;
use strict;
use warnings;
use Data::Dumper;


BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
#    plan skip_all => "TODO";
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


subtest 'simple' => sub {
    my $attr =  {
        'page' => 1,
        'rows' => 3,
        'order_by' => 'id ASC',
    };

    $rs = $skinny->resultset_dbictic( 'user_book', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:1 rows:3' );
    is( join(',', map { $_->id } $itr->all), '1,2,3', 'page1' );
    isa_ok( $itr->pager, 'Data::Page' );
    is( $itr->pager->total_entries, 11, 'total entries' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'user_book', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:2 rows:3' );
    is( join(',', map { $_->id } $itr->all), '4,5,6', 'page2' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'user_book', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:3 rows:3' );
    is( join(',', map { $_->id } $itr->all), '7,8,9', 'page3' );

    done_testing;
};


subtest 'simple group_by' => sub {
    my $attr =  {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id / ],
        'page' => 1,
        'rows' => 3,
        'order_by' => 'users.id ASC',
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:1 rows:3' );
    is( $itr->pager->total_entries, 4, 'total entries' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 1, 'page:2 rows:3' );

    done_testing;
};



subtest 'count_subref' => sub {
    my $attr =  {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id / ],
        'page' => 1,
        'rows' => 3,
        'order_by' => 'users.id ASC',
        'count_subref' => sub {
            return ('SELECT count(users.id) AS num FROM users', 'num');
        },
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:1 rows:3' );
    is( $itr->pager->total_entries, 4, 'total entries' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 1, 'page:2 rows:3' );

    done_testing;
};


subtest 'complex' => sub {

    $rs = $skinny->resultset_dbictic( 'users', {}, {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id / ],
        'having' => 'count(has_books.id) > 3',
        'page' => 1,
        'rows' => 1,
        'count_subref' => sub {
            sprintf( 'SELECT count(*) AS num FROM ( %s ) AS subquery', $rs->as_sql ), 'num';
        },
    });

    $itr = $rs->retrieve;
    is( $itr->count, 1 );
    is( $itr->pager->total_entries, 2, 'total entries' );

    done_testing;
};


subtest 'Pg: group_by' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    Mock::Pg->connect({dsn => $dsn, username => $username, password => $password});
    Mock::Pg->setup_test_db;

    $skinny = Mock::Pg->new;

    isa_ok( $skinny, 'Mock::Pg' );
    my $attr =  {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id users.name / ],
        'page' => 1,
        'rows' => 3,
        'order_by' => 'users.id ASC',
        'count_subref' => sub {
            return ('SELECT count(users.id) AS num FROM users', 'num');
        },
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:1 rows:3' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 1, 'page:2 rows:3' );

    done_testing;
};


subtest 'Pg: complex' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    isa_ok( $skinny, 'Mock::Pg' );

    $rs = $skinny->resultset_dbictic( 'users', {}, {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id users.name / ],
        'having' => 'count(has_books.id) > 3',
        'page' => 1,
        'rows' => 1,
        'count_subref' => sub {
            sprintf( 'SELECT count(*) AS num FROM ( %s ) AS subquery', $rs->as_sql ), 'num';
        },
    });

    $itr = $rs->retrieve;
    is( $itr->count, 1 );
    is( $itr->pager->total_entries, 2 );

    done_testing;
};


subtest 'mysql: group_by' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    Mock::MySQL->connect({dsn => $dsn, username => $username, password => $password});
    Mock::MySQL->setup_test_db;

    $skinny = Mock::MySQL->new;

    isa_ok( $skinny, 'Mock::MySQL' );
    my $attr =  {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id users.name / ],
        'page' => 1,
        'rows' => 3,
        'order_by' => 'users.id ASC',
        'count_subref' => sub {
            return ('SELECT count(users.id) AS num FROM users', 'num');
        },
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 3, 'page:1 rows:3' );

    $attr->{ page }++;

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 1, 'page:2 rows:3' );

    done_testing;
};


subtest 'mysql: complex' => sub {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

    isa_ok( $skinny, 'Mock::MySQL' );

    $rs = $skinny->resultset_dbictic( 'users', {}, {
        'join'     => [ qw/ has_books / ],
        'group_by' => [ qw/ users.id users.name / ],
        'having' => 'count(has_books.id) > 3',
        'page' => 1,
        'rows' => 1,
        'count_subref' => sub {
            sprintf( 'SELECT count(*) AS num FROM ( %s ) AS subquery', $rs->as_sql ), 'num';
        },
    });

    $itr = $rs->retrieve;
    is( $itr->count, 1 );
    is( $itr->pager->total_entries, 2 );

    done_testing;
};



done_testing();

