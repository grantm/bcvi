use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::BCVI',
    AUTHOR              => 'Grant McLean <grantm@cpan.org>',
    VERSION_FROM        => 'bin/bcvi',
    ABSTRACT_FROM       => 'lib/App/BCVI.pod',
    MIN_PERL_VERSION    => 5.008,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    EXE_FILES           => [ qw(bin/bcvi) ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-BCVI-*' },
);
