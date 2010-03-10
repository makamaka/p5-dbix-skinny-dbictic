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

my $skinny = Mock::SQLite->new;
my ( $itr, $rs );

subtest 'check base data' => sub {
    $skinny->setup_test_db;

    is( $skinny->search( 'users' )->count, 4, 'users' );
    is( $skinny->search( 'user_status' )->count, 4, 'user_status' );
    is( $skinny->search( 'authors' )->count, 4, 'authors' );
    is( $skinny->search( 'books' )->count, 6, 'books' );
    is( $skinny->search( 'user_book' )->count, 11, 'user_book' );

    done_testing;
};


subtest 'join user_status' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            'join'    => [ 'status' ],
            '+select' => [ 'status.flag' ],
            '+as'     => [ 'status_flag' ],
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 4, 'non where' );

    my $user = $itr->first;

    can_ok( $user, 'id' );
    can_ok( $user, 'name' );
    can_ok( $user, 'status_flag' );

    done_testing;
};


subtest 'join user_book' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            'join' => [ qw/ has_books / ],
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 12, 'non where' );

    my $user = $itr->first;

    can_ok( $user, 'id' );
    can_ok( $user, 'name' );

    $rs = $skinny->resultset_dbictic( 'users',
        { 'users.id' => 1 },
        {
            'join' => [ qw/ has_books / ],
        },
    );
    is( $rs->retrieve->count, 4, 'users.id = 1' );

    $rs = $skinny->resultset_dbictic( 'users',
        { 'users.id' => 4 },
        {
            'join' => [ qw/ has_books / ],
        },
    );
    is( $rs->retrieve->count, 1, 'users.id = 4' );

    done_testing;
};


subtest 'join user_book, books' => sub {
    my $attr = {
        'join'      => [ { 'has_books' => 'book' } ],
        '+select'   => [ 'book.title' ],
        '+as'       => [ 'book_title' ],
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 12, 'non where' );

    $rs = $skinny->resultset_dbictic( 'users', { 'users.id' => 1 }, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 4, 'users.id = 1' );

    my $data = $itr->first;

    can_ok( $data, 'book_title' );

    done_testing;
};


subtest 'join user_book, books, authors' => sub {
    my $attr = {
        'join'      => [ { 'has_books' => { 'book' => 'author' } } ],
        '+select'   => [ qw/ book.title author.name/ ],
        '+as'       => [ qw/ book_title author_name/ ],
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 12, 'non where' );

    $rs = $skinny->resultset_dbictic( 'users', { 'users.id' => 1 }, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 4, 'users.id = 1' );

    my $data = $itr->first;

    can_ok( $data, 'book_title' );
    can_ok( $data, 'author_name' );

    done_testing;
};


subtest 'join user_status user_book, books, authors' => sub {
    my $attr = {
        'join'      => [ 'status', { 'has_books' => { 'book' => 'author' } } ],
        '+select'   => [ qw/status.flag book.title author.name/ ],
        '+as'       => [ qw/status_flag book_title author_name/ ],
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );
    $itr = $rs->retrieve;
    is( $itr->count, 12 );

    my $data = $itr->first;

    can_ok( $data, 'status_flag' );
    can_ok( $data, 'book_title' );
    can_ok( $data, 'author_name' );

    done_testing;
};


subtest 'join user_book, books, authors, user_status' => sub {
    my $attr = {
        'join'      => [ { 'has_books' => { 'book' => 'author' } }, 'status' ],
        '+select'   => [ qw/status.flag book.title author.name/ ],
        '+as'       => [ qw/status_flag book_title author_name/ ],
    };

    $rs = $skinny->resultset_dbictic( 'users', {}, $attr );

    like( $rs->as_sql, qr/INNER JOIN user_status/,  'not lef join but inner join' );

    $itr = $rs->retrieve;
    is( $itr->count, 12 );

    done_testing;
};


done_testing();

