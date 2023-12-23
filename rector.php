<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\PHPUnit\CodeQuality\Rector\Class_\AddSeeTestAnnotationRector;
use Rector\PHPUnit\CodeQuality\Rector\Class_\PreferPHPUnitThisCallRector;
use Rector\PHPUnit\Set\PHPUnitLevelSetList;
use Rector\PHPUnit\Set\PHPUnitSetList;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

return static function (RectorConfig $config): void {
    $config->cacheDirectory(__DIR__ . '/build/rector');
    $config->importNames(true);
    $config->phpstanConfig(__DIR__ . '/phpstan.neon');

    $config->importShortClasses(false);
    $config->paths([
        __DIR__ . '/benchmarks',
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ]);

    $config->sets([
        LevelSetList::UP_TO_PHP_82,
        SetList::TYPE_DECLARATION,
        SetList::CODE_QUALITY,
        SetList::CODING_STYLE,
        PHPUnitLevelSetList::UP_TO_PHPUNIT_100,
        PHPUnitSetList::ANNOTATIONS_TO_ATTRIBUTES,
        PHPUnitSetList::PHPUNIT_CODE_QUALITY,
    ]);

    $config->skip([
        PreferPHPUnitThisCallRector::class,
        AddSeeTestAnnotationRector::class,
    ]);
};
