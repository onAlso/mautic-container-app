# Deploy Mautic on Azure App Service

This project uses [Composer](https://getcomposer.org/) to install Mautic inside
a docker image using GitHub Actions for deployment on Azure App Service for
custom Linux containers.

A `Makefile`, `docker-compose.yml` and `docker-compose.override.yml.dist` exist
in this repository to bring up the project locally.

## Setup Azure App Service and MySQL

> Note: The Azure MySQL database you must disable SSL connections!

## Run locally on Docker

Copy the `docker-compose.override.yml.dist` file to `docker-compose.override.yml`.

From the project root directory.

```bash
$ cp docker-compose.override.yml.dist docker-compose.override.yml
```

Adjust the values in the file accordingly to your environment and preferences.
