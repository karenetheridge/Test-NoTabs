use inc::Module::Install 0.78;

name     'Test-NoTabs';
license  'perl';
author   'Nick Gerakines <nick@socklabs.com>';
author   'Tomas Doran <bobtfish@bobtfish.net>';

all_from 'lib/Test/NoTabs.pm';
requires 'Test::More';
requires 'Test::Builder';
requires 'File::Spec';
requires 'FindBin';
requires 'File::Find';

resources repository => 'git://github.com/bobtfish/perl-test-notabs.git';

auto_install;
WriteAll;

