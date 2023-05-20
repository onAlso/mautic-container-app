# ------------------------------------------------
# makefile
# ------------------------------------------------
include config.mk

rm = rm -rf

define docker
	@echo Running $1 for ${TARGET}
	$(docker_run) $1 /bin/bash -c "$2"
endef

all: prod ${TARGET}

test: buildtest ${TARGET} runtest

dev_composer_install:
	@echo -e "\033[0;36m**\033[0;32m Running php composer install in development mode \033[0m"
	$(call docker, ${composer_image}, ${composer_devel})

composer_update:
	@echo -e "\033[0;36m**\033[0;32m Running php composer package update \033[0m"
	$(call docker, ${composer_image}, ${composer_update})

composer_install:
	@echo -e "\033[0;36m**\033[0;32m Running php composer install in production mode \033[0m"
	$(call docker, ${composer_image}, ${composer_prod})

dev_packages:  dev_composer_install

update_packages: composer_update

prod_packages: composer_install

dev: export APP_ENV = dev
dev: dev_packages
	@echo -e "\033[0;36m**\033[0;32m Building ${TARGET} in development mode \033[0m"

prod: export APP_ENV = production
prod: prod_packages
	@echo -e "\033[0;36m**\033[0;32m Building ${TARGET} in production mode \033[0m"

watch: export APP_ENV = dev
watch:
	@echo -e "\033[0;36m**\033[0;32m Building ${TARGET} in development watch mode \033[0m"

buildtest: export APP_ENV = test
buildtest: prod_packages
	@echo -e "\033[0;36m**\033[0;32m Building ${TARGET} for testing \033[0m"

runtest:
	@echo -e "\033[0;36m**\033[0;32m Starting phpunit testing... \033[0m"
	@echo -e "\033[0;36m**\033[0;32m Starting frontend regression testing... \033[0m"

${TARGET}:
	@echo Building docker image for ${TARGET}
	$(docker_build)

clean:
	@echo -e "\033[0;36m**\033[0;32m Cleaning php composer packagse and cache \033[0m"
	$(call docker, ${composer_image}, ${rm} ${composer_clean})

.PHONEY: dev test prod watch ${TARGET} clean

