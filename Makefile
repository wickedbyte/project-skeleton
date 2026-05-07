SHELL := bash

app = docker compose run --rm app

.cache:
	@docker compose build --pull
	@$(app) echo "Copying DIST Files (Overwrite Safe)" \
		&& cp --no-clobber .env.example .env \
		&& cp --no-clobber phpstan.dist.neon phpstan.neon \
		&& cp --no-clobber phpunit.dist.xml phpunit.xml
	$(app) mkdir --parents .cache
	$(app) composer install

.PHONY: clean
clean:
	@rm -rf ./.cache ./vendor

.PHONY: update
update: .cache
	@$(app) composer update --with-all-dependencies
	@$(app) composer bump

.PHONY: upgrade
upgrade: .cache
	@$(app) composer require --dev --update-with-all-dependencies \
        "php-parallel-lint/php-parallel-lint" \
        "phpstan/extension-installer" \
        "phpstan/phpstan" \
        "phpstan/phpstan-phpunit" \
        "phpunit/phpunit" \
        "psy/psysh" \
        "rector/rector" \
        "wickedbyte/coding-standard"
	@$(app) composer require --update-with-all-dependencies \
		"symfony/console"
	@$(app) app composer bump

.PHONY: bash
bash: .cache
	@$(app) bash

.PHONY: lint phpcbf phpcs phpstan phpunit rector rector-dry-run
lint phpcbf phpcs phpstan phpunit rector rector-dry-run:
	docker compose run --rm --user=$$(id -u):$$(id -g) app composer run-script "$@"

.NOTPARALLEL: ci
.PHONY: ci
ci: lint phpcs phpstan rector-dry-run phpunit
