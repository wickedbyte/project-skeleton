<?php

declare(strict_types=1);

namespace WickedByte\Benchmarks\Foo;

use PhpBench\Attributes\Iterations;
use PhpBench\Attributes\Revs;
use PhpBench\Attributes\Subject;
use WickedByte\Foo\Foo;

#[Revs(100_000)]
#[Iterations(5)]
class FooBench
{
    #[Subject]
    public function how_fast_is_42(): void
    {
        Foo::bar();
    }
}
