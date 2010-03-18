use inc::Module::Install;
name 'DBIx-Skinny-DBICTic';
all_from 'lib/DBIx/Skinny/DBICTic.pm';

requires 'DBIx::Skinny';
requires 'UNIVERSAL::require';

author_tests('xt');

build_requires 'Test::More';
repository 'http://github.com/makamaka/p5-dbix-skinny-dbictic';

use_test_base;
auto_include;

WriteAll;

1;
__END__
