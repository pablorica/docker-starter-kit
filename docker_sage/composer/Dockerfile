# docker/composer/Dockerfile
FROM wordpress:6.9.1-php8.4-apache
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN apt-get update && apt-get install -y --no-install-recommends git unzip \
 && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["composer"]