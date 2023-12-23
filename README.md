# PHP Project Skeleton (CLI)

### Setup
```shell

```

```shell
 docker compose run --rm -it app composer require --dev --update-with-all-dependencies \
  phpbench/phpbench \
  phpstan/phpstan \
  phpunit/phpunit \
  psy/psysh \
  squizlabs/php_codesniffer \
  slevomat/coding-standard \
  rector/rector

  docker compose run --rm -it app composer require --update-with-all-dependencies symfony/console

  docker compose run --rm -it app composer bump

```
