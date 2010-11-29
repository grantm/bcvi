#!perl

use strict;
use warnings;

use 5.008;

use Test::More tests => 1;

use FindBin;

my @part = File::Spec->splitdir($FindBin::Bin);
splice(@part, -1, 1, 'bin', 'bcvi');
my $path = File::Spec->catfile(@part);

require_ok($path);
