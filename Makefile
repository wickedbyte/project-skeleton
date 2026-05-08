# By default, Makefiles are executed with /bin/sh, which may not support certain
# features like `$(shell ...)` or `$(if ...)`. To ensure compatibility, we
# explicitly set the shell to bash.
SHELL := /bin/bash

# Set bash shell flags for strict error handling
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error and exit immediately.
# -o pipefail: Make pipelines (e.g. `printenv | sort` ) fail if any command in the pipeline fails.
# -c: read the command from the following string (required).
.SHELLFLAGS := -euo pipefail -c

# Optionally enable the `.ONESHELL` feature, which allows all commands in a recipe to be
# executed in the same shell instance. This is useful for maintaining state
# across commands, such as variable assignments or conditional checks.
#.ONESHELL:

# Set the default goal that will run when just invoking `make`
.DEFAULT_GOAL := .cache/.install

_WARN := "\033[33m%s\033[0m %s\n"  # Yellow text template for "printf"
_INFO := "\033[32m%s\033[0m %s\n" # Green text template for "printf"
_ERROR := "\033[31m%s\033[0m %s\n" # Red text template for "printf"

# Detect if we are in a TTY. Leave empty when stdout isn't a TTY so that Make's
# $(if ...) picks the false branch — `$(if $(IS_TTY),...)` is truthy for any
# non-empty string, including the literal "0", which silently breaks CI.
IS_TTY := $(shell [ -t 1 ] && echo 1)

##------------------------------------------------------------------------------
# Command Aliases & Function/Variable Definitions
##------------------------------------------------------------------------------

# Set COMPOSER_AUTH only when GITHUB_TOKEN is non-empty (avoids confusing 401 errors with empty tokens)
export COMPOSER_AUTH ?= $(shell \
	TOKEN=$$(grep '^GITHUB_TOKEN=' .env 2>/dev/null | cut -d= -f2); \
	if [ -n "$$TOKEN" ]; then \
		echo '{"github-oauth": {"github.com":"'$$TOKEN'"}}'; \
	fi \
)

# Define behavior to safely source file (1) to dist file (2), without overwriting
# if the dist file already exists. This is more portable than using `cp --no-clobber`.
define copy-safe
	if [ ! -f "$(2)" ]; then \
		echo "Copying $(1) to $(2)"; \
		cp "$(1)" "$(2)"; \
	else \
		echo "$(2) already exists, not overwriting."; \
	fi
endef

# Check if a token (1) is set in .env and print a helpful message if not. The token is
# optional for public packages — it only increases the GitHub API rate limit for Composer.
define check-token
	@TOKEN_VALUE=$$(grep "^$(1)=" ".env" 2>/dev/null | cut -d'=' -f2); \
	if [ -z "$$TOKEN_VALUE" ]; then \
		printf $(_WARN) "[optional]" "$(1) is not set in .env. Composer may hit GitHub API rate limits."; \
		printf $(_INFO) "" "To set it: echo '$(1)=<your-token>' >> .env"; \
	fi
endef

CACHE_DIR = .cache
CACHE_DIRS = $(CACHE_DIR)/.phpunit.cache \
	$(CACHE_DIR)/composer \
	$(CACHE_DIR)/docker \
	$(CACHE_DIR)/phpstan \
	$(CACHE_DIR)/phpunit \
	$(CACHE_DIR)/psysh \
	$(CACHE_DIR)/rector \
	$(CACHE_DIR)/xdebug

##------------------------------------------------------------------------------
# Self-Documenting Help Target
#
# Targets are documented inline by appending `## <description>` to the end of the
# rule line. The `help` target below parses those annotations and prints them.
##------------------------------------------------------------------------------

.PHONY: help
help: ## Show this help message and exit
	@printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"
	@awk 'BEGIN {FS = ":.*## "} \
		/^[a-zA-Z_][a-zA-Z0-9_-]+:.*## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST) | sort
	@printf "\n"

##------------------------------------------------------------------------------
# Docker Targets
##------------------------------------------------------------------------------

ifeq ($(shell uname -s),Darwin)
  DOCKER_UID ?= 1000
  DOCKER_GID ?= 1000
else
  DOCKER_UID ?= $(shell id -u)
  DOCKER_GID ?= $(shell id -g)
endif

docker-php = docker compose run --rm $(if $(IS_TTY),--tty,--no-TTY) php

$(CACHE_DIR)/docker/docker-compose.json: Dockerfile compose.yml | $(CACHE_DIR)/docker ## Build the project Docker image
	COMPOSE_BAKE=true docker compose build \
		--pull \
		--build-arg USER_UID=$(DOCKER_UID) \
		--build-arg USER_GID=$(DOCKER_GID)
	touch "$@" # required to consistently update the file mtime

##------------------------------------------------------------------------------
# Build/Setup/Teardown Targets
##------------------------------------------------------------------------------

.env:
	@$(call copy-safe,.env.dist,.env)

$(CACHE_DIRS): | .env
	mkdir -p "$@"

vendor/autoload.php: $(CACHE_DIR)/composer $(CACHE_DIR)/docker/docker-compose.json composer.json $(wildcard composer.lock) | .env
	@$(call check-token,GITHUB_TOKEN)
	$(docker-php) composer install
	@touch "$@"

$(CACHE_DIR)/.install : vendor/autoload.php | $(CACHE_DIRS)
	@echo "Application Build Complete."
	@touch "$(CACHE_DIR)/.install"

.PHONY: upgrade
upgrade: vendor/autoload.php ## Upgrade Composer runtime dependencies to their latest major versions
	$(docker-php) composer require -W \
		"symfony/console"
	$(docker-php) composer bump
	$(MAKE) upgrade-dev

.PHONY: upgrade-dev
upgrade-dev: vendor/autoload.php ## Upgrade Composer dev dependencies to their latest major versions
	$(docker-php) composer require --dev -W \
		"php-cs-fixer/shim" \
		"php-parallel-lint/php-parallel-lint" \
		"phpstan/extension-installer" \
		"phpstan/phpstan" \
		"phpstan/phpstan-phpunit" \
		"phpunit/phpunit" \
		"psy/psysh" \
		"rector/rector";
	$(docker-php) composer bump --dev-only

.PHONY: audit
audit: vendor/autoload.php ## Run Composer security audit against installed dependencies
	$(docker-php) composer audit

.PHONY: clean
clean: ## Remove vendor/ and the .cache/ directory
	rm -rf "$(CACHE_DIR)" "./vendor"

##------------------------------------------------------------------------------
# Code Quality, Testing & Utility Targets
##------------------------------------------------------------------------------

.PHONY: up
up: ## Start the Docker Compose services in the background
	docker compose up --detach

.PHONY: down
down: ## Stop the Docker Compose services
	docker compose down --remove-orphans

.PHONY: bash
bash: $(CACHE_DIR)/docker/docker-compose.json ## Open a bash shell inside the PHP container
	$(docker-php) bash

.PHONY: psysh
psysh: $(CACHE_DIR)/.install ## Run the PsySH PHP REPL
	$(docker-php) psysh

.PHONY: test
test: phpunit ## Alias for phpunit — run unit tests

.PHONY: lint cs-check cs-fix phpstan phpunit phpunit-coverage rector rector-dry-run
lint:             $(CACHE_DIR)/.install ## Run the PHP syntax linter (parallel-lint)
cs-check:         $(CACHE_DIR)/.install ## Check coding style with php-cs-fixer (no fixes)
cs-fix:           $(CACHE_DIR)/.install ## Apply coding style fixes with php-cs-fixer
phpstan:          $(CACHE_DIR)/.install ## Run PHPStan static analysis at level max
phpunit:          $(CACHE_DIR)/.install ## Run unit tests with PHPUnit
phpunit-coverage: $(CACHE_DIR)/.install ## Run unit tests and generate an HTML coverage report
rector:           $(CACHE_DIR)/.install ## Apply Rector refactorings
rector-dry-run:   $(CACHE_DIR)/.install ## Preview Rector refactorings without applying them
lint cs-check cs-fix phpstan phpunit phpunit-coverage rector rector-dry-run:
	$(docker-php) composer run-script "$@"

.NOTPARALLEL: ci pre-ci preci
.PHONY: ci pre-ci preci
ci: lint cs-check phpstan phpunit prettier-check rector-dry-run audit ## Run all CI checks

pre-ci: prettier-write rector cs-fix ci ## Apply formatters/fixers, then run the full CI suite
preci: pre-ci

# Run the PHP development server to serve the HTML test coverage report on port 8000 by default
COVERAGE_HTTP_PORT ?= 8000
.PHONY: serve-coverage
serve-coverage: vendor/autoload.php ## Serve the HTML coverage report on COVERAGE_HTTP_PORT (default 8000)
	@docker compose run --rm --publish $(COVERAGE_HTTP_PORT):80 php php -S 0.0.0.0:80 -t /app/$(CACHE_DIR)/phpunit

##------------------------------------------------------------------------------
# Prettier Code Formatter for JSON, YAML, HTML, Markdown, and CSS Files
# Example Usage: `make prettier-check`, `make prettier-write`
##------------------------------------------------------------------------------

.PHONY: prettier-%
prettier-%: | $(CACHE_DIR)/.install
	$(docker-php) bunx prettier --$* .

##------------------------------------------------------------------------------
# Enable Makefile Overrides
#
# If a ".local/Makefile" exists, it can define additional targets/behavior and/or
# override the targets of this Makefile. Note that this declaration has to occur
# at the end of the file in order to effect the override behavior.
##------------------------------------------------------------------------------

-include .local/Makefile
