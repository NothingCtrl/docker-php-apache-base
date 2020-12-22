# Dockerfile
FROM php:7.4.3-apache
MAINTAINER thangdb@solarbk.vn
RUN a2enmod rewrite
RUN apt update
RUN apt install nano -y
RUN apt install git -y
RUN apt install wget -y
# install needed wkhtmltopdf packages
RUN apt install libxau6 libxdmcp6 libxcb1 xfonts-base \
    libjpeg62-turbo libx11-data xfonts-75dpi fonts-dejavu-core \
    libx11-6 libxrender1 fontconfig-config libxext6 \
    libfontconfig1 fontconfig -y
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb -P /root/
RUN dpkg -i /root/wkhtmltox_0.12.5-1.buster_amd64.deb
RUN rm /root/wkhtmltox_0.12.5-1.buster_amd64.deb
RUN cp /usr/local/bin/wkhtmlto* /usr/bin/
RUN \
    cd ~ && \
    git clone https://github.com/phpredis/phpredis.git && \
    cd phpredis && phpize && \
    ./configure && \
    make && \
    make install
# Un-comment if using REDIS
RUN (echo "extension=redis.so"; echo "# session.save_handler=redis"; echo "# session.save_path=\"tcp://172.17.0.1:6379\"") > /usr/local/etc/php/conf.d/docker-php-ext-redis.ini
RUN docker-php-ext-install pdo pdo_mysql mysqli
# Install needed php extensions: ldap
RUN \
    apt update && \
    apt install libldap2-dev -y && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap
# Install xmlrpc
RUN apt update
RUN apt install -y libxml2-dev
RUN docker-php-ext-install -j$(nproc) xmlrpc
RUN apt install -y libzip-dev
#RUN docker-php-ext-install zip
RUN docker-php-ext-install -j$(nproc) zip
# Instal MS TTS font
RUN apt install -y cabextract
RUN wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
RUN dpkg -i ttf-mscorefonts-installer_3.6_all.deb
RUN rm ttf-mscorefonts-installer_3.6_all.deb
# Install GD library
RUN apt install -y zlib1g-dev libpng-dev libjpeg-dev libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
# Install ping command
RUN apt install -y iputils-ping
# install socket
RUN docker-php-ext-install sockets
# xdebug
ARG XDEBUG_VERSION=2.9.4
RUN mkdir -p /usr/src/php/ext/xdebug && \
    curl -fsSL https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz | tar xz -C /usr/src/php/ext/xdebug --strip 1 && \
    docker-php-ext-install xdebug && \
    echo '[xdebug] \n\
xdebug.remote_host = "172.17.0.1" \n\
xdebug.default_enable = 1 \n\
xdebug.remote_autostart = 1 \n\
xdebug.remote_connect_back = 0 \n\
xdebug.remote_enable = 1 \n\
xdebug.remote_handler = "dbgp" \n\
xdebug.remote_port = 9000' >> /usr/local/etc/php/php.ini
RUN apt update && apt install -y dnsutils