SHELL := bash

app = docker compose run --rm app

build:
	@docker compose build --pull
	@$(app) echo "Copying DIST Files (Overwrite Safe)" \
		&& cp --no-clobber .env.example .env \
		&& cp --no-clobber phpstan.dist.neon phpstan.neon \
		&& cp --no-clobber phpunit.dist.xml phpunit.xml
	$(app) mkdir --parents build
	$(app) composer install

.PHONY: clean
clean:
	@rm -rf ./build ./vendor

.PHONY: update
update: build
	@$(app) composer update --with-all-dependencies
	@$(app) composer bump

.PHONY: upgrade
upgrade: build
	@$(app) composer require --dev --update-with-all-dependencies \
		phpstan/phpstan \
		phpunit/phpunit \
		psy/psysh \
		squizlabs/php_codesniffer \
		slevomat/coding-standard \
		rector/rector
	@$(app) composer require --update-with-all-dependencies \
		symfony/console
	@$(app) app composer bump

.PHONY: bash
bash: build
	@$(app) bash

.PHONY: phpunit
phpunit: build
	@$(app) composer phpunit

.PHONY: psysh
psysh: build
	@$(app) composer psysh

.PHONY: phpcs
phpcs: build
	@$(app) composer phpcs

.PHONY: phpcbf
phpcbf: build
	@$(app) composer phpcbf

.PHONY: phpstan
phpstan: build
	@$(app) composer phpstan

.PHONY: rector
rector: build
	@$(app) composer rector

.PHONY: ci
ci: build
	@$(app) composer ci
