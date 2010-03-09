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

my $rs = $skinny->resultset_dbictic( 'user_profile',
    undef,
    {
        'select' => [ 'user_profile.id' ],
        'order_by' => 'id ASC',
    }
);

my $it = $rs->retrieve;

is( $it->next->id, 1 );


done_testing();

