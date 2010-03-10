package Mock::Pg::Schema;
use utf8;
use DBIx::Skinny::Schema;
use DBIx::Skinny::DBICTic::Schema;


install_table 'users' => schema {
    pk 'id';
    columns qw( id name );
    # Relationship
    has_many 'has_books' => 'user_book' => 'users.id = user_book.user_id';
    has_one  'status'    => 'user_status' => 'users.id = user_status.user_id';
};


install_table 'user_status' => schema {
    pk 'user_id';
    columns qw( user_id flag );
    # Relationship
    belongs_to 'owner' => 'users' => 'users.id = user_status.user_id';
};


install_table 'user_book' => schema {
    pk 'id';
    columns qw( id user_id book_id number );
    # Relationship
    belongs_to 'user' => 'users' => 'user_book.user_id = users.id';
    belongs_to 'book' => 'books' => 'user_book.book_id = books.id';
};


install_table 'books' => schema {
    pk 'id';
    columns qw( id title author_id );
    belongs_to 'author' => 'authors' => 'books.author_id = authors.id';
};


install_table 'authors' => schema {
    pk 'id';
    columns qw( id name );
    has_many 'written_books' => 'books' => 'authors.id = books.author_id';
};


1;
__END__
