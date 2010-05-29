#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::BCVI::InstallManager' );
}

diag( "Testing App::BCVI::InstallManager $App::BCVI::InstallManager::VERSION, Perl $], $^X" );
