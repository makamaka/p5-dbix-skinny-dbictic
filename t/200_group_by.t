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
    is( $skinny->search( 'authors' )->count, 4, 'authors' );
    is( $skinny->search( 'books' )->count, 6, 'books' );
    is( $skinny->search( 'user_book' )->count, 11, 'user_book' );

    done_testing;
};


subtest 'group_by' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            'join'     => [ qw/ has_books / ],
            'group_by' => [ qw/ users.id / ],
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 4, 'group_by users.id' );

    done_testing;
};


subtest 'group_by, +select' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        {
            '+select'  => [ 'count(has_books.id)' ],
            '+as'      => [ 'book_num' ],
            'join'     => [ qw/ has_books / ],
            'group_by' => [ qw/ users.id / ],
            'order_by' => 'users.id ASC',
        },
    );

    $itr = $rs->retrieve;

    is( $itr->count, 4, 'group_by users.id' );

    my $user = $itr->next;

    is( $user->book_num, 4 );

    done_testing;
};



done_testing();

