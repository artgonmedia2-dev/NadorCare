# Image de développement de l'API Nador Care (PHP 8.4).
# Une seule image sert l'API, Horizon, Reverb et le planificateur : seule la commande change.
FROM php:8.4-cli-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_pgsql pgsql redis pcntl intl gd zip bcmath sockets exif opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "upload_max_filesize=20M" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "post_max_size=25M" >> /usr/local/etc/php/conf.d/nadorcare.ini

WORKDIR /var/www/api

EXPOSE 8000 8080

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
