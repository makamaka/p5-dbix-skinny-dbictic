use lib './t';
use Test::More;
use Test::Exception;

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
#
#

my $itr;
my $rs;

$rs = $skinny->resultset_dbictic( 'user',
    { 'user.id' => $user2->id },
    {
        'join'    => [ 'profiles' ],
    }
);

isa_ok( $rs, 'DBIx::Skinny::SQL' );

like( $rs->as_sql, qr/
    \QSELECT user.id, user.name\E
    \s+\QFROM user LEFT JOIN user_profile ON user.id = user_profile.user_id\E
    \s+\QWHERE (user.id = ?)\E
/xi, 'simple join - no selct' );

is( $rs->retrieve->count, 3 );


$rs = $skinny->resultset_dbictic( 'user',
    undef,
    {
        'join'    => [ 'profiles', 'status' ],
    }
);

like( $rs->as_sql, qr/
    \QSELECT user.id, user.name\E
    \s+\QFROM user\E
    \s+\QLEFT JOIN user_profile ON user.id = user_profile.user_id\E
    \s+\QLEFT JOIN user_status ON user.id = user_status.user_id\E
/xi, 'multiple join - no selct' );

is( $rs->retrieve->count, 5 );


$rs = $skinny->resultset_dbictic( 'user',
    { 'user.id' => $user->id },
    {
        'join'    => [ 'profiles' ],
        '+select' => [ 'profiles.name', 'profiles.value' ],
        '+as'     => [ 'prof_name', 'value' ],
    }
);


like( $rs->as_sql, qr/
    \QSELECT user.id, user.name, user_profile.name AS prof_name, user_profile.value\E
    \s+\QFROM user LEFT JOIN user_profile ON user.id = user_profile.user_id\E
    \s+\QWHERE (user.id = ?)\E
/xi, '+select - join alias' );


$rs = $skinny->resultset_dbictic( 'user',
    { user_id => $user->id },
    {
        'join'    => [ 'profiles' ],
        '+select' => [ 'user_profile.name', 'user_profile.value' ],
        '+as'     => [ 'prof_name', 'value' ],
    }
);


like( $rs->as_sql, qr/
    \QSELECT user.id, user.name, user_profile.name AS prof_name, user_profile.value\E
    \s+\QFROM user LEFT JOIN user_profile ON user.id = user_profile.user_id\E
    \s+\QWHERE (user_id = ?)\E
/xi, '+select - original name' );


$rs = $skinny->resultset_dbictic( 'user',
    { 'status.value' => 'hoge' },
    { join => [ 'status' ],  }
);



$rs = $skinny->resultset_dbictic( 'user',
    {},
    { join => [ 'status', 'profiles' ],  }
);


$rs = $skinny->resultset_dbictic( 'user',
    {},
    {
        '+select' => [ 'count(user_profile.name)' ],
        '+as'     => [ 'prof_num' ],
        join => [ 'profiles' ],
        group_by => [ 'user.id' ],
        having => { 'prof_num' => \do{ '> 2' } }, # sqlite
    }
);

#print $rs->as_sql, ";bind:";
#print join( ',', @{ $rs->bind } ), "\n";

$itr = $rs->retrieve;

is( $itr->count, 1 );
is( $itr->first->name, 'b' );


# using SQL::Abstract
$rs = $skinny->resultset_dbictic( 'user',
    {},
    {
        use_sql_abstract => 1,
        '+select' => [ 'count(user_profile.name)' ],
        '+as'     => [ 'prof_num' ],
        join => [ 'profiles' ],
        group_by => [ 'user.id' ],
        having => { 'prof_num' => \do{ '> 2' } }, # sqlite
    }
);


$itr = $rs->retrieve;

is( $itr->count, 1 );

done_testing();
