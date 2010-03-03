use lib './t';
use Test::More;
use strict;
use warnings;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

use Mock::Basic;

my $skinny = Mock::Basic->new;
$skinny->setup_test_db;


my $user = $skinny->insert( 'user', { name => 'a' } );

$skinny->insert( 'user_profile', { user_id => $user->id, name => 'profile_1', value => 'AAA' } );
$skinny->insert( 'user_profile', { user_id => $user->id, name => 'profile_2', value => 'BBB' } );
$skinny->insert( 'user_status', { user_id => $user->id, status => 'foobar' } );

my $user2 = $skinny->insert( 'user', { name => 'b' } );

$skinny->insert( 'user_profile', { user_id => $user2->id, name => 'profile_1', value => 'CCC' } );
$skinny->insert( 'user_profile', { user_id => $user2->id, name => 'profile_2', value => 'DDD' } );
$skinny->insert( 'user_profile', { user_id => $user2->id, name => 'profile_3', value => 'EEE' } );
$skinny->insert( 'user_status', { user_id => $user2->id, status => 'hoge' } );

#
# check table
#

is( $user->id, 1 );
is( $user2->id, 2 );
is( $skinny->search( 'user' )->count, 2, 'user table ok' );
is( $skinny->search( 'user_profile' )->count, 5, 'user_profile table ok' );
is( $skinny->search( 'user_status' )->count, 2, 'user_status table ok' );

#

my $rs = $skinny->resultset_dbictic( 'user_profile',
    undef,
    {
        page => 1, rows => 2, order_by => 'id ASC',
    }
);

my $itr = $rs->retrieve;
my $pager = $itr->pager;

isa_ok( $pager, 'Data::Page' );

is( $pager->total_entries, 5, '$pager->total_entries' );

#my $itr = $rs->retrieve;

is( $itr->count, 2 );
is( $itr->next->id, 1 );
is( $itr->next->id, 2 );

$rs = $skinny->resultset_dbictic( 'user_profile',
    undef,
    {
        page => 2, rows => 2, order_by => 'id ASC',
    }
);

$itr = $rs->retrieve;

is( $itr->pager->total_entries, 5, '$pager->total_entries' );

is( $itr->count, 2 );
is( $itr->next->id, 3 );
is( $itr->next->id, 4 );


$rs = $skinny->resultset_dbictic( 'user_profile',
    undef,
    {
        group_by => [ 'user_id' ], page => 1, rows => 10, order_by => 'id ASC',
    }
);

$itr = $rs->retrieve;

is( $itr->pager->total_entries, 2, 'group_by $pager->total_entries' );


$rs = $skinny->resultset_dbictic( 'user_profile',
    undef,
    {
        select => [ 'id' ],
        page => 1, rows => 10, order_by => 'id ASC',
        count_subref => sub {
            my ( $sql ) = @_;
            like( $sql, qr/SELECT id\s+FROM/, 'count_subref' );
            return ( 'SELECT count(*) as foobar FROM user_profile', 'foobar' );
        },
    }
);

$itr = eval q{ $rs->retrieve };

ok( $itr );


done_testing();
