# Image de développement de l'API Nador Care (PHP 8.4).
# Une seule image sert l'API, Horizon, Reverb et le planificateur : seule la commande change.
FROM php:8.4-cli-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_pgsql pgsql redis pcntl intl gd zip bcmath sockets exif opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "upload_max_filesize=20M" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "post_max_size=25M" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    # Le code est monté depuis l'hôte : le cache d'opcodes évite de relire des milliers de fichiers à chaque requête.
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "opcache.max_accelerated_files=30000" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "realpath_cache_size=4096K" >> /usr/local/etc/php/conf.d/nadorcare.ini \
    && echo "realpath_cache_ttl=600" >> /usr/local/etc/php/conf.d/nadorcare.ini

WORKDIR /var/www/api

EXPOSE 8000 8080

# Serveur PHP intégré plutôt que `artisan serve` : ce dernier relit .env et ignorerait
# les variables fournies par Docker (hôtes de la base et de Redis).
ENV PHP_CLI_SERVER_WORKERS=4
# Le routeur de Laravel attend d'être lancé depuis le dossier public.
CMD ["sh", "-c", "cd public && exec php -S 0.0.0.0:8000 ../vendor/laravel/framework/src/Illuminate/Foundation/resources/server.php"]
