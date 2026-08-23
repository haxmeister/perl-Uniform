use strict;
use warnings;

use Test::More;
use Test::Deep;
use Uniform::Utils qw(normalize_http_headers);

# 1. Setup a complex mock environment combining every edge case your code catches
my $messy_environment = {
    'HTTP_HX_TARGET' => 'loser-env-variable',
    'HX-Target'      => 'winner-real-header',
    '  hx_boosted  ' => 'true',
    'hx-trigger'     => [ 'ignored-first-id', 'winning-last-id' ],
    'hx-evil-inject; content' => 'should-be-dropped-entirely',
};

my $normalized = normalize_http_headers($messy_environment);

# 2. Assert structural correctness using Test::Deep
cmp_deeply(
    $normalized,
    {
        'hx-target'  => 'winner-real-header', # Score ranking victory
        'hx-boosted' => 'true',               # Whitespace and case cleanup
        'hx-trigger' => 'winning-last-id',    # Array reduction filter
    },
    'Centralized normalization engine processes edge cases flawlessly'
);

done_testing();
