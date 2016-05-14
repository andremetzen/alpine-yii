FROM alpine:3.3
MAINTAINER Andre Metzen <metzen@conceptho.com>

RUN apk add --update bash curl git nginx ca-certificates \
    php-fpm php-json php-zlib php-xml php-pdo php-phar php-openssl php-dom php-intl php-ctype \
    php-pdo_mysql php-mysqli php-memcache \
    php-gd php-iconv php-mcrypt nodejs musl && rm -rf /var/cache/apk/*

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer
RUN composer global require "fxp/composer-asset-plugin:~1.1.3"

ENV PATH /root/.composer/vendor/bin:$PATH
RUN npm install -g bower

ADD files /src
RUN cp -rf /src/* /
RUN rm -rf /src

EXPOSE 80

CMD ["bash", "/start.sh"]
