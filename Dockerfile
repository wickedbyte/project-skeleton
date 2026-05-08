# syntax=docker/dockerfile:1.4
ARG PHP_IMAGE_TAG=8.5-cli
FROM php:${PHP_IMAGE_TAG} AS php
WORKDIR /app

# Create Non-Root User Account
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=dev
RUN <<-EOF
  set -eux
  groupadd --gid ${USER_GID} ${USER_NAME};
  useradd --system --create-home --uid ${USER_UID} --gid ${USER_GID} --groups www-data --shell /bin/bash ${USER_NAME};
EOF

# Upgrade Dependencies and Install Required System Packages
RUN --mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
  set -eux
  apt-get update;
  apt-get dist-upgrade --yes;
  apt-get install ---yes --quiet --no-install-recommends \
    git \
    less \
    libzip-dev \
    unzip;
  apt-get clean;
EOF

# Install Composer
ENV COMPOSER_HOME="/home/${USER_NAME}/.composer"
ENV COMPOSER_CACHE_DIR="/app/.cache/composer"
ENV COMPOSER_ROOT_VERSION="0.0.1"
ENV PATH="/app/bin:/app/vendor/bin:${COMPOSER_HOME}/vendor/bin:${PATH}"
COPY --link --from=composer /usr/bin/composer /usr/local/bin/composer
COPY --link --from=composer --chown=$USER_UID:$USER_GID /tmp/* ${COMPOSER_HOME}/

# Install and Compile PHP Extensions with PIE
COPY --link --from=ghcr.io/php/pie:bin /pie /usr/local/bin/pie
RUN docker-php-ext-install zip
RUN pie install xdebug/xdebug

# Configure the PHP Runtime
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --link <<-EOF /usr/local/etc/php/conf.d/settings.ini
	memory_limit=1G
	assert.exception=1
	error_reporting=E_ALL
	display_errors=1
	log_errors=on
	xdebug.log_level=0
	xdebug.mode=debug
	xdebug.client_host=host.docker.internal
	xdebug.start_with_request=trigger
	xdebug.idekey=PHPSTORM
	xdebug.output_dir=/app/.cache/xdebug
EOF

# Install Bun and Prettier
# We have to create our own executable wrapper for prettier to ensure  that it
# is run via `bun x`, otherwise, it fails with a missing Node error. Additionally,
# note that we have to switch to the non-root user in order to install Prettier.
# (This is why we create the wrapper before installing the actual binary.)
COPY --link --from=oven/bun:slim /usr/local/bin/bun /usr/local/bin/bunx /usr/local/bin/
USER ${USER_NAME}
RUN bun add --global --exact prettier
