use lib './t';
use Test::More;
use strict;
use warnings;
use Data::Dumper;


BEGIN {
    eval "use DBD::SQLite";
#    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
    plan skip_all => "TODO";
}

use Mock::SQLite;

my $skinny = Mock::SQLite->new;
my ( $itr, $rs );


done_testing();

