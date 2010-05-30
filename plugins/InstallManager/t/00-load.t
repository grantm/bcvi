#!perl

use File::Spec qw();
use Test::More;

my $bin_file = find_bcvi();

if(not $bin_file) {
    plan skip_all => 'App::BCVI does not appear to be installed';
    exit(0);
}

eval { require $bin_file };
if($@) {
    plan skip_all => qq{Your bcvi installation ($bin_file) appears to be old/broken: "$@"};
    exit(0);
}

plan tests => 1;

use_ok('App::BCVI::InstallManager');

exit;



sub find_bcvi {
    foreach my $dir (File::Spec->path) {
        my $path = File::Spec->catfile($dir, 'bcvi');
        return $path if -x $path;
    }
    return;
}

