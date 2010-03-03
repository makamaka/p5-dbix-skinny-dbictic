package DBIx::Skinny::DBICTic;

use strict;
use warnings;

our $VERSION = '0.01';

1;
__END__

=pod

=encoding utf8

=head1 NAME

DBIx::Skinny::DBICTic - dbic-like interface

=head1 SYNOPSIS

    package Your::Model::Schema;
    use DBIx::Skinny::Schema;
    use DBIx::Skinny::DBICTic::Schema;
    
    install_table 'user' => schema {
        pk 'id';
        columns qw/
            id name
        /;
        
        # Relationship
        has_many 'profiles'
                    => 'user_profile' => 'user.id = user_profile.user_id';
        might_have 'status'
                    => 'user_status'  => 'user.id = user_status.user_id';
        
        # 汎用
        relationship 'hoge'
                    => 'user_status' => {
                        condition => 'user.id user_status.user_id',
                        type => 'inner',
                    };
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
    
    
    package Your::Model;
    
    use DBIx::Skinny setup => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    
    use DBIx::Skinny::Mixin modules => [ qw(DBICTic) ];
    
    
    package main;
    
    my $skinny = Your::Model->new;
    
    my $rs = $skinny->resultset_dbictic( 'user',
        { 'user.id' => 1 },
        {
            'join'    => [ 'profiles' ],
            '+select' => [ qw( profiles.name profiles.value ) ],
            '+as'     => [ qw( prof_name prof_value ) ],
        }
    );
    
    my $itr = $rs->retrieve;
    
    $rs = $skinny->resultset_dbictic( 'user',
        undef,
        {
            order_by => 'id DESC',
            page     => 1,
            rows     => 10,
        }
    );
    
    $itr = $rs->retrieve;
    
    my $pager = $itr->pager;

=head1 VERSION

  0.01

=head1 DESCRIPTION

DBIx::Skinnyのresultsetみたいなインターフェースを提供する。

=head1 SCHEMA FEATURE

=head2 relationship

  relationship $join_name, $join_table, { condition => $cond, type => $type };

C<join>に指定する名前、joinするテーブル名、ハッシュを引数に取る。
ハッシュはC<add_join>に渡す値C<condition>, C<type>を含む。

=head2 has_one

  has_one $join_name, $join_table, $condtion;

少しだけ楽をするためのもの。

=head2 might_have

  might_have $join_name, $join_table, $condtion;

少しだけ楽をするためのもの。

=head2 has_many

  has_many $join_name, $join_table, $condtion;

少しだけ楽をするためのもの。

=head2 belongs_to

  belongs_to $join_name, $join_table, $condtion;

少しだけ楽をするためのもの。

=head1 METHOD

=head2 resultset_dbictic

  $rs = $skinny->resultset_dbictic( $table, $where, $attr );

L<DBIx::Class::Resultset>っぽい値を渡せる。$attrに使えるキーはL</RESULTSET FEATURE>を参照。
L<DBIx::Skiny::SQL>を継承したオブジェクトL<DBIx::Skiny::SQL::DBICTic>を返す。

C<page>とC<rows>を指定した場合、c<retrieve>が返すイテレータのpagerメソッドで
L<Data::Page>オブジェクトが返る。


=head1 RESULTSET FEATURE

=head2 join

  join => $listref

schema内でrelationshipで設定した名前を指定する。

=head2 select

  select => $listref

selectしたいカラムを指定する。

=head2 as

  as => $listref

selectで指定したカラムのエイリアスを設定する。

=head2 +select

  +select => $listref

デフォルトで設定されてるカラムに追加する。

=head2 +as

  +as => $listref

+selectで指定したカラムのエイリアスを設定する。

=head2 order_by

  order_by => $scalar

order by。

=head2 limit

  limit => $scalar

limit。

=head2 page

  page => $scalar

rowsと一緒に使ってページを指定する。

=head2 rows

  rows => $scalar

1ページに載せる行数。

=head2 group_by

  group_by => $listref

group by。

=head2 having

  having => $hashref
  having => $arrayref

havingの指定。

=head2 count_subref

  count_subref => sub {
      my $sql = shift;
      return ( $str, $column );
  }

page指定したときのcount用ステートメンスとカラムを返すサブルーチンリファレンス。引数にSQL文をとる。
デフォルトで

    sub {
        my $str = $_[0];
        $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT COUNT(*) FROM}i;
        return ( $str, 'COUNT(*)' );
    };

となる。group_byを使用している場合は

    sub {
        my $str = $_[0];
        my $column =  sprintf( 'COUNT(DISTINCT(%s))', join( ',', @{ $attr->{ group_by } } ) );
        $str =~ s{^\s*SELECT\s+(?:.+?)\s+FROM}{SELECT $column FROM}i;
        $str =~ s{GROUP\s+BY\s+(?:[.\w]+,?\s*){1,}}{}i;
        return ( $str, $column );
    };

になってる。


=head2 use_sql_abstract

C<$where>とC<having>の値に対してL<SQL::Abstract>が適用される。

=head1 SEE ALSO

L<DBIx::Skinny>,
L<DBIx::Class::Resultset>,
L<SQL::Abstract>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
