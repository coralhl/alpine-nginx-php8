FROM coralhl/alpine-base:latest

LABEL Maintainer="coral xciii <coralhl@gmail.com>" \
      Description="Lightweight container with Nginx & PHP-FPM 8 based on Alpine Linux."

ARG PHP_VER_NUM="83"
ARG PHP_VER="php"$PHP_VER_NUM

ENV PHP_VER=$PHP_VER
ENV PHP_VER_NUM=$PHP_VER_NUM
ENV TZ=Europe/Moscow

USER root

# Install packages and remove default server definition
RUN apk --no-cache add ${PHP_VER} \
    ${PHP_VER}-bcmath \
    ${PHP_VER}-cli \
    ${PHP_VER}-ctype \
    ${PHP_VER}-curl \
    ${PHP_VER}-dom \
    ${PHP_VER}-exif \
    ${PHP_VER}-fileinfo \
    ${PHP_VER}-fpm \
    ${PHP_VER}-ftp \
    ${PHP_VER}-gd \
    ${PHP_VER}-iconv \
    ${PHP_VER}-imap \
    ${PHP_VER}-intl \
    ${PHP_VER}-mbstring \
    ${PHP_VER}-mysqli \
    ${PHP_VER}-opcache \
    ${PHP_VER}-openssl \
    ${PHP_VER}-pcntl \
    ${PHP_VER}-pdo \
    ${PHP_VER}-pdo_mysql \
    ${PHP_VER}-pdo_pgsql \
    ${PHP_VER}-pdo_sqlite \
    ${PHP_VER}-pgsql \
    ${PHP_VER}-pecl-imagick \
    ${PHP_VER}-pecl-memcache \
    ${PHP_VER}-pecl-memcached \
    ${PHP_VER}-pecl-msgpack \
    ${PHP_VER}-pecl-redis \
    ${PHP_VER}-phar \
    ${PHP_VER}-posix \
    ${PHP_VER}-session \
    ${PHP_VER}-simplexml \
    ${PHP_VER}-soap \
    ${PHP_VER}-sodium \
    ${PHP_VER}-sqlite3 \
    ${PHP_VER}-tokenizer \
    ${PHP_VER}-xml \
    ${PHP_VER}-xmlreader \
    ${PHP_VER}-xmlwriter \
    ${PHP_VER}-zip \
    ${PHP_VER}-zlib \
    bash dcron libcap nginx mysql-client postgresql-client supervisor \
  && ${PHP_VER} -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && ${PHP_VER} composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && ln -snf /usr/sbin/php-fpm${PHP_VER_NUM} /usr/bin/php-fpm

# Configure Supervisord
COPY config/supervisord.conf /etc/supervisord.conf
COPY config/sv-php-fpm.conf /etc/supervisor/conf.d/php-fpm.conf
COPY config/sv-nginx.conf /etc/supervisor/conf.d/nginx.conf

# Configure Nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx-default.conf /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/${PHP_VER}/php-fpm.d/www.conf
COPY config/php.ini /etc/${PHP_VER}/conf.d/custom.ini

# Copy tools
COPY start.sh /start.sh

# Setup dirs
RUN  mkdir -p /var/log/supervisor \
  && mkdir -p /var/www/html \
  && mkdir -p /var/log/php \
# Make sure files/folders needed by the processes are accessable when they run under the abc user (uid 1000)
  && chown -R abc:abc /var/www/html \
  && chown -R abc:abc /var/log/nginx \
  && chown -R abc:abc /var/log/php \
# Set default timezone  
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
# Set path in php-fpm.conf
  && sed -i 's|/etc/php/|/etc/'"$PHP_VER"'/|' /etc/supervisor/conf.d/php-fpm.conf \
# Allow to start service as non-root and bind to "privileged" ports (ports less than 1024)
  #&& setcap 'cap_net_bind_service=+ep' /usr/bin/php83 \
  && chmod +x /start.sh

# Add application
WORKDIR /var/www/html
COPY --chown=abc web/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/start.sh"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
