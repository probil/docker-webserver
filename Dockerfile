FROM ubuntu:14.04.1
MAINTAINER Ivan Pushkin <imetalguardi+docker@gmail.com>

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TERM xterm
ENV MYSQL_USER root
ENV MYSQL_PASSWORD ""
ENV NGINX_VERSION 1.6.2-1~trusty
ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.22-2ubuntu14.04
ENV PHP_VERSION 5.6.4+dfsg-1+deb.sury.org~trusty+1
ENV HOSTNAME docker.dev

RUN \

# utf locale
	locale-gen $LC_ALL && \

# add nginx repository
	apt-key adv --keyserver pgp.mit.edu --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 && \
	echo "deb http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list && \

# add mysql repository
	apt-key adv --keyserver pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5 && \
	echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -cs) mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list && \

# add ondrej php repository
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 14AA40EC0831756756D7F66C4F4EA0AAE5267A6C && \
	echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" > /etc/apt/sources.list.d/php.list && \

# update
	apt-get update && \

# install all packages
	DEBIAN_FRONTEND=noninteractive apt-get -y -q --no-install-recommends install \
		nano \
		openssl \
		ca-certificates \
		nginx=$NGINX_VERSION \
		supervisor \
		mysql-server=$MYSQL_VERSION \
		mysql-client \
		curl \
		wget \
		git \
		php5-fpm=$PHP_VERSION \
		php5-cli \
		php5-mysql \
		php5-curl \
		php5-gd \
		php5-intl \
		php5-imagick \
		php5-mcrypt \
		php5-memcached \
		php5-json \
		phpmyadmin && \

# install composer
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \

# add user "docker" to use it as default user for working with files
	yes "" | adduser --uid=1000 --disabled-password docker && \

# install composer assets plugin
	sudo -H -u docker bash -c "/usr/local/bin/composer global require fxp/composer-asset-plugin:1.0.0-beta4" && \

# create and set access to the folder
	mkdir -p /web/docker && \
	echo "<?php echo 'web server is running';" > /web/docker/index.php && \
	chown -R docker:docker /web && \

# add custom php configuration
	mkdir -p /etc/php5/fpm/conf.d && \
	mkdir -p /etc/php5/cli/conf.d && \
	cd /etc/php5/fpm/conf.d && \
	ln -sf ../../mods-available/custom.php.ini ./20-custom.php.ini && \
	cd /etc/php5/cli/conf.d && \
	ln -sf ../../mods-available/custom.php.ini ./20-custom.php.ini && \

# set access and error nginx logs to stdout and stderr
	ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log && \

# clean apt cache and temps
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY configs/mysql.sh /opt/mysql.sh

COPY configs/php-fpm.conf /etc/php5/fpm/php-fpm.conf

COPY configs/phpmyadmin.php /etc/phpmyadmin/conf.d/phpmyadmin.php

COPY configs/default.conf /etc/nginx/conf.d/default.conf

COPY configs/custom.php.ini /etc/php5/mods-available/custom.php.ini

EXPOSE 80 443 3306 9000

VOLUME ["/web", "/var/lib/mysql"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]