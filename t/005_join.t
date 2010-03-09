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


=pod

subtest 'non where - attribute select' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        { 'select' => [ qw/ id / ] },
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'id' );

    ok( not eval q{ $user->name } );

    done_testing;
};


subtest 'non where - attribute select, as' => sub {
    $rs = $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'select' => [ qw/ id / ],
            'as'     => [ qw/ foobar / ],
        },
    );

    $itr = $rs->retrieve;

    my $user = $itr->first;

    can_ok( $user, 'foobar' );

    ok( not eval q{ $user->id } );

    done_testing;
};


subtest 'non where - attribute as only' => sub {
    $rs = eval { $skinny->resultset_dbictic( 'users',
        {}, 
        {
            'as'     => [ qw/ foobar hoge / ],
        },
    ) };

    like( $@, qr/'as' is set but 'select' is not set/ );


    done_testing;
};

=cut

done_testing();

