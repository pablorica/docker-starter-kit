# docker/php/Dockerfile
FROM php:8.4-fpm

# System deps
RUN apt-get update && apt-get install -y \
    git curl zip unzip tzdata bash \
    libonig-dev libicu-dev \
    libpng-dev libjpeg62-turbo-dev libwebp-dev libfreetype6-dev \
    libzip-dev \
    libmagickwand-dev \
 && rm -rf /var/lib/apt/lists/*
 
# ---- PHP extensions commonly required by Statamic/Laravel ---- #
# gd (image manipulation), intl (i18n), mbstring, zip, exif, opcache, bcmath (often handy)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install -j"$(nproc)" gd intl mbstring zip exif opcache bcmath

# ---- Install Imagick ---- #
RUN pecl install imagick \
  && docker-php-ext-enable imagick


# Composer
ENV COMPOSER_HOME=/tmp/composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# PHP ini
COPY conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY conf.d/custom.ini  /usr/local/etc/php/conf.d/custom.ini

WORKDIR /var/www/html

# (Optional) simple healthcheck: ensure FPM listens
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD php -r 'echo "OK";' || exit 1

CMD ["php-fpm"]