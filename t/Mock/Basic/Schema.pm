package Mock::Basic::Schema;
use utf8;
use DBIx::Skinny::Schema;
use DBIx::Skinny::DBICTic::Schema;


install_table 'user' => schema {
    pk 'id';
    columns qw/
        id name
    /;
    # Relationship
    has_many 'profiles' => 'user_profile' => 'user.id = user_profile.user_id';
    might_have 'status' => 'user_status'  => 'user.id = user_status.user_id';
    # 汎用
    relationship 'hoge'
        => { table => 'user_status', condition => 'user.id = user_status.user_id', type => 'inner' };
};


install_table 'user_profile' => schema {
    pk 'id';
    columns qw/
        id user_id name value
    /;
};


install_table 'user_status' => schema {
    pk 'user_id';
    columns qw/
        user_id status
    /;
};

1;

