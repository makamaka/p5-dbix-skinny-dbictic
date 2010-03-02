package Mock::BasicMySQL;
use DBIx::Skinny setup => +{};

my $table = 'mock_basic_mysql';
sub setup_test_db {
    my $self = shift;
    $self->do(qq{
        DROP TABLE IF EXISTS $table
    });

    $self->do(qq{
        CREATE TABLE $table (
            id   INT auto_increment,
            name TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
}

use DBIx::Skinny::Plus;

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

