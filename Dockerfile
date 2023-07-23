# syntax=docker/dockerfile:1.4
FROM php:8.2-cli as base
WORKDIR /app
ENV PATH /app/bin:/app/vendor/bin::/home/dev/.composer/vendor/bin/:$PATH
RUN groupadd --gid 1000 dev \
    && useradd --system --create-home --uid 1000 --gid 1000 --shell /bin/bash dev
RUN apt-get update  \
    && apt-get install -y \
        apt-transport-https \
        autoconf  \
        build-essential \
        curl \
        git \
        less \
        libgmp-dev \
        libicu-dev \
        libzip-dev \
        libsodium-dev \
        pkg-config \
        unzip \
        vim \
        zip \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install -j$(nproc) bcmath gmp intl opcache zip
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
RUN mkdir -p "/home/dev/.composer" \
    && chown -R "dev:dev" "/home/dev/.composer"

FROM base as php
USER dev

FROM base as php-xdebug
RUN pecl install xdebug  \
    && docker-php-ext-enable xdebug
USER dev
