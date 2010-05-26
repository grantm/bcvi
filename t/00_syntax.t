#!perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;

my @part = File::Spec->splitdir($FindBin::Bin);
splice(@part, -1, 1, 'bin', 'bcvi');
my $path = File::Spec->catfile(@part);

my $output = `perl -c $path 2>&1`;

if($? == 0) {
    ok(1, 'syntax chack of bin/bcvi');
}
else {
    ok(0, 'syntax chack of bin/bcvi');
    diag($output);
}

