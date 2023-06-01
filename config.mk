# target
TARGET=mautic

UID=$(shell id -u)
GID=$(shell id -g)

docker_run=docker run --rm -t -v ${PWD}:/var/www -e HOME=/var/www -e COMPOSER_HOME=/var/www/.local/share/composer --user ${UID}:${GID}
docker_build=docker build --build-arg APP_ENV=${APP_ENV} -t ${TARGET}:latest .

#composer_image=zealbyte/php-composer
composer_image=onalso/mautic-cli:latest
composer_prod=php composer.phar install --no-dev --prefer-dist --optimize-autoloader
composer_devel=php composer.phar install
composer_update=php composer.phar update
composer_clean=\
	bin/* \
	docroot/* \
	vendor

