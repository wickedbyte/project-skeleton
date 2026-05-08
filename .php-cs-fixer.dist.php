<?php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

return new Config()
    ->setCacheFile(__DIR__ . '/.cache/php-cs-fixer.cache')
    ->setFinder(
        new Finder()
            ->in(__DIR__)
            ->exclude(['vendor', 'build'])
            ->notName('*.php.inc')
    )
    ->setRiskyAllowed(true)
    ->setRules([
        '@auto' => true,
        '@auto:risky' => true,
        'nullable_type_declaration' => ['syntax' => 'union']
    ]);
