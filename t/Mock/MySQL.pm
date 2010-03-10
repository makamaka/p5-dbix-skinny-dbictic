package Mock::MySQL;

#use DBIx::Skinny::Profiler::ProfileLogger;
use DBIx::Skinny setup => +{
#    profiler => DBIx::Skinny::Profiler::ProfileLogger->new,
};

use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];


sub setup_test_db {
    my $self = shift;

    for my $table ( qw( users user_status user_book books authors ) ) {
        eval { $self->do(qq{
            DROP TABLE IF EXISTS $table
        }) };
    }

    $self->do(q{
        CREATE TABLE users (
            id      integer auto_increment,
            name    text,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE user_status (
            user_id integer,
            flag    integer,
            primary key( user_id )
        )
    });

    $self->do(q{
        CREATE TABLE user_book (
            id      integer auto_increment,
            user_id integer,
            book_id integer,
            number  integer default 1,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE books (
            id          integer auto_increment,
            title       text,
            author_id   integer,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE authors (
            id          integer auto_increment,
            name        text,
            primary key( id )
        )
    });

    my $user_a = $self->insert( 'users', { name => 'a' } );
    my $user_b = $self->insert( 'users', { name => 'b' } );
    my $user_c = $self->insert( 'users', { name => 'c' } );
    my $user_d = $self->insert( 'users', { name => 'd' } );

    $self->insert( 'user_status', { user_id => $user_a->id, flag => 100 } );
    $self->insert( 'user_status', { user_id => $user_b->id, flag => 200 } );
    $self->insert( 'user_status', { user_id => $user_c->id, flag => 300 } );
    $self->insert( 'user_status', { user_id => $user_d->id, flag => 400 } );

    my $author_a = $self->insert( 'authors', { name => 'AUTHOR A' } );
    my $author_b = $self->insert( 'authors', { name => 'AUTHOR B' } );
    my $author_c = $self->insert( 'authors', { name => 'AUTHOR C' } );
    my $author_d = $self->insert( 'authors', { name => 'AUTHOR D' } );

    my $book_a1  = $self->insert( 'books', { title => 'BOOK A1', author_id => $author_a->id } );
    my $book_a2  = $self->insert( 'books', { title => 'BOOK A2', author_id => $author_a->id } );
    my $book_a3  = $self->insert( 'books', { title => 'BOOK A3', author_id => $author_a->id } );
    my $book_b1  = $self->insert( 'books', { title => 'BOOK B1', author_id => $author_b->id } );
    my $book_b2  = $self->insert( 'books', { title => 'BOOK B2', author_id => $author_b->id } );
    my $book_c1  = $self->insert( 'books', { title => 'BOOK C1', author_id => $author_c->id } );

    # user_a
    $self->insert( 'user_book', { user_id => $user_a->id, book_id => $book_a1->id } );
    $self->insert( 'user_book', { user_id => $user_a->id, book_id => $book_a2->id } );
    $self->insert( 'user_book', { user_id => $user_a->id, book_id => $book_b1->id } );
    $self->insert( 'user_book', { user_id => $user_a->id, book_id => $book_c1->id } );

    # user_b
    $self->insert( 'user_book', { user_id => $user_b->id, book_id => $book_a1->id } );
    $self->insert( 'user_book', { user_id => $user_b->id, book_id => $book_b1->id } );
    $self->insert( 'user_book', { user_id => $user_b->id, book_id => $book_b2->id } );
    $self->insert( 'user_book', { user_id => $user_b->id, book_id => $book_c1->id } );

    # user_c
    $self->insert( 'user_book', { user_id => $user_c->id, book_id => $book_a1->id } );
    $self->insert( 'user_book', { user_id => $user_c->id, book_id => $book_a2->id } );
    $self->insert( 'user_book', { user_id => $user_c->id, book_id => $book_c1->id } );
}

sub cleanup_test_db {
}

1;

