package Mock::Basic;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];

sub setup_test_db {
    my $self = shift;

    for my $table ( qw( user user_profile user_status ) ) {
        $self->do(qq{
            DROP TABLE IF EXISTS $table
        });
    }

    $self->do(q{
        CREATE TABLE user (
            id      integer,
            name    text,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE user_profile (
            id      integer,
            user_id integer,
            name    text,
            value   text,
            primary key( id )
        )
    });

    $self->do(q{
        CREATE TABLE user_status (
            user_id integer,
            status  text,
            primary key( user_id )
        )
    });


}

sub creanup_test_db {
}


1;

