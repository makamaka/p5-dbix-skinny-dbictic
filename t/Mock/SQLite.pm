package Mock::SQLite;

use DBIx::Skinny::Profiler::ProfileLogger;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    profiler => DBIx::Skinny::Profiler::ProfileLogger->new,
};

use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];

sub setup_test_db {
    my $self = shift;

    for my $table ( qw( users user_book books authors ) ) {
        $self->do(qq{
            DROP TABLE IF EXISTS $table
        });
    }

    $self->do(q{
        CREATE TABLE users (
            id      integer,
            name    text,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE user_book (
            id      integer,
            user_id integer,
            book_id integer,
            number  integer default 1,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE books (
            id          integer,
            title       text,
            author_id   integer,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE authors (
            id          integer,
            name        text,
            primary key( id )
        )
    });


}

sub creanup_test_db {
}


1;

