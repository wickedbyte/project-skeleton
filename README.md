# PHP Project Skeleton (CLI)

An opinionated template for PHP CLI projects, optimized for getting a development
environment running quickly. Everything builds and runs inside Docker, with caches
consolidated under `.cache/` and a Makefile orchestrating the common workflow.

> This template targets development. Production deployment is intentionally left
> to the consuming project — there are too many environment-specific factors
> (orchestration, secrets, observability, etc.) to bake in sensible defaults.

## Requirements

- Docker (with the `compose` plugin / Compose v2)
- GNU Make
- Optional: a GitHub token in `.env` to lift Composer's API rate limit on public packages

## Quick Start

```sh
make           # build the image and install vendor dependencies
make bash      # open a shell inside the PHP container
make ci        # run the full CI suite locally
make help      # list every documented Make target
```

The first invocation copies `.env.dist` to `.env` (without overwriting an existing
file), builds the project Docker image, and runs `composer install`.

## Common Make Targets

Run `make help` for the full list. Highlights:

| Target                       | Purpose                                                        |
| ---------------------------- | -------------------------------------------------------------- |
| `make`                       | Build the image and install dependencies (default goal).       |
| `make bash`                  | Open a bash shell inside the container.                        |
| `make psysh`                 | Run the PsySH PHP REPL                                         |
| `make up` / `make down`      | Start / stop the Compose services in the background.           |
| `make phpunit` / `make test` | Run unit tests.                                                |
| `make phpunit-coverage`      | Run unit tests and generate an HTML coverage report.           |
| `make serve-coverage`        | Serve the latest HTML coverage report on port 8000.            |
| `make cs-check` / `cs-fix`   | Check / apply coding-style fixes via php-cs-fixer.             |
| `make phpstan`               | Run PHPStan at level `max`.                                    |
| `make rector`                | Apply Rector refactorings (`rector-dry-run` to preview).       |
| `make lint`                  | Run the PHP syntax linter (parallel-lint).                     |
| `make ci`                    | Run lint, cs-check, phpstan, phpunit, prettier, rector, audit. |
| `make pre-ci`                | Run formatters/fixers, then `ci`.                              |
| `make audit`                 | Run `composer audit` against installed dependencies.           |
| `make upgrade`               | Bump dependencies to their latest major versions.              |
| `make clean`                 | Remove `vendor/` and `.cache/`.                                |

For anything not exposed as a Make target:

```sh
docker compose run --rm php <your-command-here>
```

## Customizing the Template

When forking this template into a new project, update the following:

- `composer.json` — `name`, `description`, `authors`, and the PSR-4 namespaces
  (`WickedByte\App\` → your namespace; `WickedByte\Tests\App\` → your test namespace).
- `bin/app` — the `Application` name and any commands you want registered.
- `src/` and `tests/` — replace the `Foo` / `FooCommand` / `FooTest` placeholders.
- `compose.yml` — change the `name:` default (or set `COMPOSE_PROJECT_NAME` in
  `.env`) to namespace your Compose project.
- `LICENSE` — update the copyright holder if applicable.
- `.env.dist` — adjust `PHP_IMAGE_TAG` if you target a different PHP minor version.

The Makefile sources `.local/Makefile` if it exists, so personal/per-machine
overrides can be added without modifying the tracked Makefile.

## Local Configuration

- `.env` is created from `.env.dist` on first build and is gitignored.
- A `GITHUB_TOKEN` in `.env` is **optional** — it only raises the GitHub API
  rate limit Composer hits when resolving public packages. No scopes required.
- Xdebug is preinstalled but disabled by default (`XDEBUG_MODE=off`). Set
  `XDEBUG_MODE=debug` in `.env` and restart the container to enable step debugging.

## License

[MIT](LICENSE)
