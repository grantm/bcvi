#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'this test is for release candidate testing');
  }
}

use Test::More;

my $release_version = get_release_version('dist.ini');
my $script_version  = get_script_version('bin/bcvi');

is($script_version, $release_version, "version in script");

done_testing();
exit;


sub get_release_version {
    my($path) = @_;

    open my $fh, '<', $path or die "open($path): $!";
    while(<$fh>) {
        if(/^version\s+=\s+(\S+)/) {
            return $1;
        }
    }
}

sub get_script_version {
    my($path) = @_;

    open my $fh, '<', $path or die "open($path): $!";
    while(<$fh>) {
        if(/^our \$VERSION\s+=\s+'(\S+)'/) {
            return $1;
        }
    }
}
