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

my $rs = $skinny->resultset_dbictic( 'user',
    undef,
    {
        'join'    => [ 'profiles', 'status' ],
    }
);

like( $rs->as_sql, qr/SELECT user.id, user.name\s+FROM/ );
like( $rs->as_sql, qr/\s+JOIN\s+/ );

$rs->add_select( 'foo' );

like( $rs->as_sql, qr/SELECT user.id, user.name, foo\s+FROM/ );
like( $rs->as_sql, qr/\s+JOIN\s+/ );


#
#
#

$rs = Mock::Basic->resultset_dbictic( 'user',
    undef,
    {
        'join'    => [ 'profiles', 'status' ],
    }
);

$rs = $skinny->resultset_dbictic( 'user',
    undef,
    {
        'join'    => [ 'profiles', 'status' ],
    }
);

like( $rs->as_sql, qr/SELECT user.id, user.name\s+FROM/ );
like( $rs->as_sql, qr/\s+JOIN\s+/ );

$rs->add_select( 'foo' );

like( $rs->as_sql, qr/SELECT user.id, user.name, foo\s+FROM/ );
like( $rs->as_sql, qr/\s+JOIN\s+/ );

done_testing();
