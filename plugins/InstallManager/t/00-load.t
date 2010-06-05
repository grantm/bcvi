#!perl

use File::Spec qw();
use Test::More tests => 1;

my $bin_file = find_bcvi();

if(not $bin_file) {
    diag 'App::BCVI does not appear to be installed';
    ok(1);
    exit(0);
}

eval { require $bin_file };
if($@) {
    diag qq{Your bcvi installation ($bin_file) appears to be old/broken: "$@"};
    ok(1);
    exit(0);
}

use_ok('App::BCVI::InstallManager');

exit;



sub find_bcvi {
    foreach my $dir (File::Spec->path) {
        my $path = File::Spec->catfile($dir, 'bcvi');
        return $path if -x $path;
    }
    return;
}

