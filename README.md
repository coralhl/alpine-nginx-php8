
# Docker PHP-FPM 8 & Nginx on 🏔️ Alpine Linux

![size](https://img.shields.io/docker/image-size/coralhl/alpine-nginx-php8/latest?color=0eb305) ![version](https://img.shields.io/docker/v/coralhl/alpine-nginx-php8/latest?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/coralhl/alpine-nginx-php8?color=2b75d6) ![stars](https://img.shields.io/docker/stars/coralhl/alpine-nginx-php8?color=e6a50e) [<img src="https://img.shields.io/badge/github-coralhl-blue?logo=github">](https://github.com/coralhl)

* Built on the lightweight and secure Alpine Linux distribution
* Small Docker image size (+/-60MB)
* Uses PHP 8 for better performance, lower CPU usage & memory footprint
* Optimized for ~20 concurrent users
* Optimized to use low amount of resources when there's no traffic (by using PHP-FPM's dynamic PM)
* The servers Nginx, PHP-FPM and supervisord run under a non-privileged user to make it more secure
* Follows the KISS principle (Keep It Simple, Stupid) to make it easy to understand and adjust the image to your needs

![nginx 1.26.3](https://img.shields.io/badge/nginx-1.26-brightgreen.svg)
![php 8](https://img.shields.io/badge/php-8.4-brightgreen.svg)
![php 8](https://img.shields.io/badge/php-8.3-brightgreen.svg)
![php 8](https://img.shields.io/badge/php-8.2-brightgreen.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

**Tags:** alpine-nginx-php8: latest, 8.4, 8.3, 8.2

**NOTE** If you are upgrading from PHP **8.1 to 8.2** or from **8.2 to 8.3** or from **8.3 to 8.4**, you may need to run `composer update` to upgrade php packages, because some packages under 8.1/8.2 are not supported in 8.2/8.3 or 8.3/8.4

## Includes

* bash
* dcron
* Composer
* GD2
* Various other extensions (like SimpleXML, see below)
* MySQL CLI
* PostgreSQL CLI

This image is built on GitHub actions and available on [Docker Hub](https://hub.docker.com/r/coralhl/alpine-nginx-php8).

## Usage

```
docker pull coralhl/alpine-nginx-php8/alpine-nginx-php8:latest
```
or
```
docker pull coralhl/alpine-nginx-php8/alpine-nginx-php8:php8.3
```

### COMPOSE
```yaml
services:
  php82:
    image: coralhl/alpine-nginx-php8:8.2
    container_name: php82
    environment:
      TZ: Europe/Moscow
    restart: always
```

### DEFAULT SETTINGS
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | abc | user inside docker |
| `user's home` | /home/user | home directory of user abc |
| `www` | /var/www/html | webroot content directory (see `WEBROOT`) |
| `conf` | /var/www/html/conf | you can put your files `nginx.conf` and `nginx-site.conf` in this directory or your own config file |
| `scripts` | /var/www/html/scripts | this directory can contain your scripts that will be run when the container starts up |
| `supervisor logs` | /var/log/supervisor | supervisor logs is saved here by default |
| `nginx logs` | /var/log/nginx | nginx logs is saved here by default |
| `php logs` | /var/log/php | php logs is saved here by default |

### ENVIRONMENT
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | Europe/Moscow |
| `PUID` | non-privileged user id | 1000 |
| `PGID` | non-privileged group id | 1000 |
| `WEBROOT` | for example `/home/user/www` | /var/www/html |
| `CHOWN_WEBROOT` | 1 (on) / - (off) | 0 (not chown `WEBROOT`) |
| `ERRORS` | 1 (on) / - (off) | 0 (php_flag[display_errors] = off) |
| `PHP_ERRORS_STDERR` | 1 (on) / - (off) | 0 (/var/log/php/error.log) |
| `PHP_MEM_LIMIT` | 1024M | memory_limit = 128M |
| `PHP_POST_MAX_SIZE` | 2048M | post_max_size = 100M |
| `PHP_UPLOAD_MAX_FILESIZE` | 3072M | upload_max_filesize = 100M |
| `PHP_REDIS_SESSION_HOST` | 192.168.1.10 | session.save_handler = files |
| `REAL_IP_HEADER` | 1 (on) / - (off) | 0 (#real_ip_header X-Forwarded-For; #set_real_ip_from ) |
| `REAL_IP_FROM` | 192.168.1.0/24 | - |
| `RUN_SCRIPTS` | 1 (on) / - (off) | 0 (not launch scripts from /var/www/html/scripts/*) |

## Configuration
In [config/](config/) you'll find the default configuration files for Nginx, PHP and PHP-FPM.
If you want to extend or customize that you can do so by mounting a configuration file in the correct folder.

You may check [start.sh](https://github.com/coralhl/alpine-nginx-php8/blob/master/start.sh) for more information about what it can do.

## PHP Modules

In this image it contains following PHP modules:

```
# php -m
[PHP Modules]
bcmath
Core
ctype
curl
date
dom
exif
fileinfo
filter
ftp
gd
hash
iconv
igbinary
imagick
imap
intl
json
libxml
mbstring
memcache
memcached
msgpack
mysqli
mysqlnd
openssl
pcntl
pcre
PDO
pdo_mysql
pdo_pgsql
pdo_sqlite
pgsql
Phar
posix
random
readline
redis
Reflection
session
SimpleXML
soap
sockets
sodium
SPL
sqlite3
standard
tokenizer
xml
xmlreader
xmlwriter
Zend OPcache
zip
zlib

[Zend Modules]
Zend OPcache
```

## BUILT WITH
* [mimalloc](https://github.com/coralhl/alpine-base-docker)

## TIPS