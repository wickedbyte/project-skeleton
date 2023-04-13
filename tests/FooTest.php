<?php

declare(strict_types=1);

namespace WickedByte\Tests\Foo;

use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;
use WickedByte\Foo\Foo;

#[CoversClass(Foo::class)]
class FooTest extends TestCase
{
    #[Test]
    public function bar_returns_42(): void
    {
        self::assertSame(42, Foo::bar());
    }
}
