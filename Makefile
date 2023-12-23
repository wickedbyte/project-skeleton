SHELL := bash

app = docker compose run --rm app

build:
	@docker compose build --pull
	@$(app) mkdir -p build
	@$(app) composer install

.PHONY: update
update:
	@$(app) composer update --with-all-dependencies
	@$(app) composer bump

.PHONY: upgrade
upgrade:
	@$(app) composer require --dev --update-with-all-dependencies \
		phpbench/phpbench \
		phpstan/phpstan \
		phpunit/phpunit \
		psy/psysh \
		squizlabs/php_codesniffer \
		slevomat/coding-standard \
		rector/rector
	@$(app) composer require --update-with-all-dependencies \
		symfony/console
	@$(app) app composer bump

.PHONY: clean
clean:
	@rm -rf ./build ./vendor

.PHONY: bash
bash:
	@$(app) bash

.PHONY: phpunit
phpunit:
	@$(app) composer phpunit

.PHONY: phpbench
phpbench:
	@$(app) composer phpbench

.PHONY: psysh
psysh:
	@$(app) composer psysh

.PHONY: phpcs
phpcs:
	@$(app) composer phpcs

.PHONY: phpcbf
phpcbf:
	@$(app) composer phpcbf

.PHONY: phpstan
phpstan:
	@$(app) composer phpstan

.PHONY: rector
rector:
	@$(app) composer rector

.PHONY: ci
ci:
	@$(app) composer ci
