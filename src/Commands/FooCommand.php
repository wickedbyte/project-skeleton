<?php

declare(strict_types=1);

namespace WickedByte\App\Commands;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use WickedByte\App\Foo;

class FooCommand extends Command
{
    #[\Override]
    protected function configure(): void
    {
        $this->setName('foo')
            ->setDescription('Placeholder Command');
    }

    #[\Override]
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln("Hello, World! - " . Foo::bar());
        return self::SUCCESS;
    }
}
