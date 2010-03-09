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


subtest 'non where - order by' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {},
        { order_by => 'id DESC' },
    );

    is( join( ',', map { $_->id } $rs->retrieve->all ), '4,3,2,1', 'id DESC' );

    $rs = $skinny->resultset_dbictic( 'users',
        {},
        { order_by => 'id ASC' },
    );

    is( join( ',', map { $_->id } $rs->retrieve->all ), '1,2,3,4', 'id ASC' );

    done_testing;
};



done_testing();

