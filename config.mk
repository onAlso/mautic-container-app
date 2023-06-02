# target
TARGET=mautic

UID=$(shell id -u)
GID=$(shell id -g)

docker_run=docker run --rm -t -v ${PWD}/mautic:/var/www/html -e HOME=/var/www/html -e COMPOSER_HOME=/var/www/html/.local/share/composer --user ${UID}:${GID}
docker_build=docker build --build-arg APP_ENV=${APP_ENV} -t ${TARGET}:latest .

#composer_image=zealbyte/php-composer
composer_image=onalso/mautic-cli:latest
composer_prod=composer install --no-dev --prefer-dist --optimize-autoloader
composer_devel=composer install
composer_update=composer update
composer_clean=\
	mautic/app \
	mautic/bin \
	mautic/docroot \
	mautic/vendor \
	mautic/*.php \
	mautic/*.js

