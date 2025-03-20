#!/bin/bash

### Enable custom nginx config files if they exist
if [ -f /var/www/html/conf/nginx.conf ]; then
  cp /var/www/html/conf/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f /var/www/html/conf/nginx-site.conf ]; then
  cp /var/www/html/conf/nginx-site.conf /etc/nginx/conf.d/default.conf
fi

### Display PHP error's or not
if [[ "$ERRORS" == "1" ]] ; then
  sed -i "s|php_flag[display_errors] = off|php_flag[display_errors] = on|" /etc/$PHP_VER/php-fpm.d/www.conf
fi

### Display errors in docker logs
if [ "$PHP_ERRORS_STDERR" == "1" ]; then
  sed -i "s|/var/log/php/error.log|/dev/stderr|" /etc/$PHP_VER/conf.d/custom.ini
  sed -i "s|/var/log/php/error.log|/dev/stderr|" /etc/$PHP_VER/php-fpm.d/www.conf
fi

### Pass real-ip to logs when behind ELB, etc
if [[ "$REAL_IP_HEADER" == "1" ]] ; then
  sed -i "s|#real_ip_header X-Forwarded-For;|real_ip_header X-Forwarded-For;|" /etc/nginx/conf.d/default.conf
  sed -i "s|#set_real_ip_from|set_real_ip_from|" /etc/nginx/conf.d/default.conf
  if [ ! -z "$REAL_IP_FROM" ]; then
    sed -i "s|172.16.0.0/12|$REAL_IP_FROM|" /etc/nginx/conf.d/default.conf
  fi
fi

### Set the desired timezone
if [ ! -z "$TZ" ]; then
  sed -i "s|^date.timezone=".*"|date.timezone="'${TZ}'"|" /etc/$PHP_VER/conf.d/custom.ini
  rm -f /etc/localtime && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

### Set custom webroot
if [ ! -z "$WEBROOT" ]; then
  sed -i "s|root /var/www/html;|root ${WEBROOT};|g" /etc/nginx/conf.d/default.conf
else
  WEBROOT="/var/www/html"
fi

### Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
  sed -i "s|memory_limit = 128M|memory_limit = ${PHP_MEM_LIMIT}|" /etc/$PHP_VER/conf.d/custom.ini
fi

### Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
  sed -i "s|post_max_size = 100M|post_max_size = ${PHP_POST_MAX_SIZE}|" /etc/$PHP_VER/conf.d/custom.ini
fi

### Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
  sed -i "s|upload_max_filesize = 100M|upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}|" /etc/$PHP_VER/conf.d/custom.ini
fi

### Use redis as session storage
if [ ! -z "$PHP_REDIS_SESSION_HOST" ]; then
  sed -i "s|session.save_handler = files|session.save_handler = redis\nsession.save_path = "tcp://'${PHP_REDIS_SESSION_HOST}':6379"|" /etc/$PHP_VER/conf.d/custom.ini
fi

### Run custom scripts
if [[ "$RUN_SCRIPTS" == "1" ]] ; then
  if [ -d "/var/www/html/scripts/" ]; then
    # make scripts executable incase they aren't
    chmod -Rf 750 /var/www/html/scripts/*; sync;
    # run scripts in number order
    for i in `ls /var/www/html/scripts/`; do /var/www/html/scripts/$i ; done
  else
    echo "Can't find script directory"
  fi
fi

### Set user
PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

echo '
     ┌                            ┐
                                
       ███ ███ ██████ ███ ███ ███  
      ░███░███░██████░███░███░███  
      ░███████░███░░ ░███░███░███  
      ░░░███░ ░███   ░███░███░███  
       ███████░███   ░███░███░███  
      ░███░███░██████░███░███░███  
      ░███░███░██████░███░███░███  
      ░░░ ░░░ ░░░░░░ ░░░ ░░░ ░░░   
     └                            ┘
           Created by XCIII:
      https://github.com/coralhl/

───────────────────────────────────────'
echo "
PUID                    = $(id -u abc)
PGID                    = $(id -g abc)
───────────────────────────────────────
TZ                      = $TZ
WEBROOT                 = $WEBROOT
CHOWN_WEBROOT           = $CHOWN_WEBROOT
ERRORS                  = $ERRORS
RUN_SCRIPTS             = $RUN_SCRIPTS
───────────────────────────────────────
REAL_IP_HEADER          = $REAL_IP_HEADER
REAL_IP_FROM            = $REAL_IP_FROM
───────────────────────────────────────
PHP_ERRORS_STDERR       = $PHP_ERRORS_STDERR
PHP_MEM_LIMIT           = $PHP_MEM_LIMIT
PHP_POST_MAX_SIZE       = $PHP_POST_MAX_SIZE
PHP_UPLOAD_MAX_FILESIZE = $PHP_UPLOAD_MAX_FILESIZE
PHP_REDIS_SESSION_HOST  = $PHP_REDIS_SESSION_HOST
───────────────────────────────────────
"

chown -R abc:abc /etc/nginx
chown -R abc:abc /etc/supervisor/conf.d/
chown -R abc:abc /var/log

### Chown /var/www/html
if [[ "$CHOWN_WEBROOT" == "1" ]] ; then
  echo "Chowning $WEBROOT for user abc
───────────────────────────────────────"
  chown -R abc:abc $WEBROOT
else
  echo "NOT chowning $WEBROOT for user abc. Do it yourself
───────────────────────────────────────"
fi

### Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
