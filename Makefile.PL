use inc::Module::Install;
name 'DBIx-Skinny-DBICTic';
all_from 'lib/DBIx/Skinny/DBICTic.pm';

requires 'DBIx::Skinny' => '0.0725';
requires 'UNIVERSAL::require';
requires 'SQL::Abstract';
requires 'Data::Page';

author_tests('xt'); # requires Module::Install::AuthorTests


build_requires 'Test::More' => '0.96';



repository 'http://github.com/makamaka/p5-dbix-skinny-dbictic';

use_test_base; # requires Test::Base
auto_include;

WriteAll;

1;
__END__
