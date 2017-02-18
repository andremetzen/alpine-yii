FROM alpine:3.4
MAINTAINER Andre Metzen <metzen@conceptho.com>

ENV TIMEZONE=America/Sao_Paulo \
    PHP_MEMORY_LIMIT=128M MAX_UPLOAD=8M PHP_MAX_FILE_UPLOAD=8M PHP_MAX_POST=8M \
    NGINX_VERSION=1.10.1

# enable edge & testing repo
RUN sed -i -e 's/v3\.4/edge/g' /etc/apk/repositories && \
	echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# let's roll
RUN	apk update && \
	apk upgrade && \
	apk add --update tzdata && \
	ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone && \
	apk add --update \
	bash curl git ca-certificates nodejs \
	php7-fpm php7-json php7-zlib php7-xml php7-pdo php7-phar php7-curl php7-openssl php7-dom php7-intl php7-ctype \
    php7-pdo_mysql php7-mysqli php7-opcache php7-memcached php7-redis \
    php7-gd php7-iconv php7-mcrypt php7-mbstring php7-session && \
	sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = 9000|g" /etc/php7/php-fpm.conf && \
    sed -i "s|;*listen\s*=\s*/||g" /etc/php7/php-fpm.conf && \
    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini && \
    ln -s /usr/bin/php7 /usr/bin/php && \
    apk del tzdata && \
	rm -rf /var/cache/apk/*

# nginx
RUN \
  build_pkgs="build-base linux-headers openssl-dev pcre-dev wget zlib-dev" && \
  runtime_pkgs="ca-certificates openssl pcre zlib" && \
  apk --update add ${build_pkgs} ${runtime_pkgs} && \
  cd /tmp && \
  wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar xzf nginx-${NGINX_VERSION}.tar.gz && \
  cd /tmp/nginx-${NGINX_VERSION} && \
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
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  adduser -D nginx && \
  mkdir /var/cache/nginx && \
  rm -rf /tmp/* && \
  apk del ${build_pkgs} && \
  rm -rf /var/cache/apk/*

RUN apk add --update xvfb ttf-freefont fontconfig dbus \
      && apk add qt5-qtbase-dev wkhtmltopdf --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
      && mv /usr/bin/wkhtmltopdf /usr/bin/wkhtmltopdf-origin \
      && echo $'#!/usr/bin/env sh\n\
  Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & \n\
  DISPLAY=:0.0 wkhtmltopdf-origin $@ \n\
  killall Xvfb\
  ' > /usr/bin/wkhtmltopdf && \
      chmod +x /usr/bin/wkhtmltopdf \
      && mv /usr/bin/wkhtmltoimage /usr/bin/wkhtmltoimage-origin \
      && echo $'#!/usr/bin/env sh\n\
  Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & \n\
  DISPLAY=:0.0 wkhtmltoimage-origin $@ \n\
  killall Xvfb\
  ' > /usr/bin/wkhtmltoimage && \
      chmod +x /usr/bin/wkhtmltoimage \
    && rm -rf /var/cache/apk/*

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer
RUN composer global require "fxp/composer-asset-plugin:~1.2"

ENV PATH /root/.composer/vendor/bin:$PATH
RUN npm install -g bower

COPY files /

EXPOSE 80

CMD ["bash", "/start.sh"]
