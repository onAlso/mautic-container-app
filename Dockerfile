FROM php:7.4-apache

ARG TIMEZONE=UTC
ARG APP_DOMAIN=web.onalso.com
ARG SERVER_ADMIN=info@onalso.com
ARG APP_ENV=prod

ENV APP_ENV $APP_ENV
ENV SSH_PASSWD "root:Docker!"

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
  && printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini \
	&& "date"

# install tools and PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		cron \
		openssh-server \
		; \
		\
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	apt-get install -y --no-install-recommends \
		freetds-dev \
		libgmp-dev \
		libzip-dev \
		libwebp-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libbz2-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libc-client-dev \
    libkrb5-dev \
    zlib1g-dev \
    libicu-dev \
    libsqlite3-dev \
    libpspell-dev \
    libreadline-dev \
    libedit-dev \
    librecode-dev \
    libsnmp-dev \
    libtidy-dev \
    libxslt1-dev \
    libgmp-dev \
    libldb-dev \
    libldap2-dev \
    libsodium-dev \
    librabbitmq-dev \
	; \
	\
	docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
	docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
	docker-php-ext-install -j$(nproc) \
		bcmath \
		bz2 \
		calendar \
		exif \
		gd \
		gettext \
		gmp \
		iconv \
		imap \
		intl \
		ldap \
		pcntl \
		pdo \
		pdo_mysql \
		snmp \
		soap \
		sockets \
		tidy \
		xsl \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
	{ \
		echo 'memory_limit = 1024M'; \
		echo 'max_input_vars = 1000'; \
		echo 'upload_max_filesize = 100M'; \
		echo 'post_max_size = 100M'; \
		echo 'expose_php = Off'; \
	} > /usr/local/etc/php/conf.d/application-recommended.ini; \
	{ \
		echo "EnableMMAP Off"; \
		echo "EnableSendFile Off"; \
	} > /etc/apache2/conf-available/docker-azure-appservice.conf; \
	{ \
		echo "ServerName ${APP_DOMAIN}"; \
	} > /etc/apache2/conf-available/docker-recommended.conf; \
	{ \
		echo "<VirtualHost *:80>"; \
		echo "\tServerName ${APP_DOMAIN}"; \
		echo "\tServerAlias *.${APP_DOMAIN}"; \
		echo "\tServerAdmin ${SERVER_ADMIN}"; \
		echo "\tDocumentRoot /var/www/docroot"; \
		echo "\tSetEnv APP_ENV \${APP_ENV}"; \
		echo "</VirtualHost>"; \
	} | tee /etc/apache2/sites-available/000-default.conf

COPY --chown=www-data:www-data . /var/www

ENV PATH="/var/www/docroot/bin:${PATH}"

RUN \
	mkdir -p /tmp/; \
	mv /var/www/index_dev.php /var/www/docroot/index_dev.php; \
	mv /var/www/docker-entrypoint.sh /usr/local/bin/; \
	mv /var/www/mautic_crontab /etc/cron.d/;\
	mv /var/www/ssh_setup.sh /tmp/; \
	mv /var/www/sshd_config /etc/ssh/; \
	chown root:root /tmp/ssh_setup.sh; \
	chown root:root /etc/ssh/sshd_config; \
	chown root:root /usr/local/bin/docker-entrypoint.sh; \
	chown root:root /etc/cron.d/mautic_crontab; \
	chmod a+rx /tmp/ssh_setup.sh; \
	chmod a+rx /usr/local/bin/docker-entrypoint.sh; \
	chmod 0644 /etc/cron.d/mautic_crontab; \
	touch /var/log/cron.log

RUN \
	echo "$SSH_PASSWD" | chpasswd; \
	(sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

RUN \
	a2enconf docker-recommended docker-azure-appservice; \
	a2enmod rewrite expires

VOLUME /home

WORKDIR /var/www

EXPOSE 80 2222

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]

