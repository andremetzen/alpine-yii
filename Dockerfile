FROM alpine:3.8
MAINTAINER Andre Metzen <metzen@conceptho.com>

RUN apk add --update bash curl git ca-certificates \
    php5-fpm php5-json php5-zlib php5-xml php5-pdo php5-phar php5-curl \
    php5-openssl php5-dom php5-intl php5-ctype \
    php5-pdo_mysql php5-mysqli php5-opcache php5-cli \
    php5-gd php5-iconv php5-mcrypt nodejs \
    libgcc libstdc++ libx11 glib libxrender libxext libintl \
    libcrypto1.0 libssl1.0 \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family \
    && rm -rf /var/cache/apk/* \
    && mv /usr/bin/php5 /usr/bin/php

RUN \
  build_pkgs="build-base linux-headers openssl-dev pcre-dev wget zlib-dev" && \
  runtime_pkgs="ca-certificates openssl pcre zlib" && \
  apk --update add ${build_pkgs} ${runtime_pkgs} && \
  cd /tmp && \
  wget http://nginx.org/download/nginx-1.10.0.tar.gz && \
  tar xzf nginx-1.10.0.tar.gz && \
  cd /tmp/nginx-1.10.0 && \
  ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-ipv6 \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module && \
  make && \
  make install && \
  sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf && \
  adduser -D nginx && \
  rm -rf /tmp/* && \
  apk del ${build_pkgs} && \
  rm -rf /var/cache/apk/*

RUN mkdir /var/cache/nginx

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer
RUN composer global require "fxp/composer-asset-plugin:~1.1.3"

RUN apk add npm

ENV PATH /root/.composer/vendor/bin:$PATH
RUN npm install -g bower

COPY files /

RUN chmod +x /usr/bin/wkhtmltopdf

EXPOSE 80

CMD ["bash", "/start.sh"]
