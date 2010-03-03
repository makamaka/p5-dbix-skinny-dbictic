use inc::Module::Install;
name 'DBIx-Skinny-DBICTic';
all_from 'lib/DBIx/Skinny/DBICTic.pm';

requires 'DBIx::Skinny';
requires 'UNIVERSAL::require';

author_tests('xt');

build_requires 'Test::More';

use_test_base;
auto_include;
auto_set_repository;
WriteAll;

1;
__END__
