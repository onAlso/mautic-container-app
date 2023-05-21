#!/bin/bash
log(){
	while read line ; do
		echo "`date '+%D %T'` $line"
	done
}

set -e
user="${APACHE_RUN_USER:-www-data}"
group="${APACHE_RUN_GROUP:-www-data}"
docroot="/var/www/html"
dataroot="/var/www/data"


# Copy over Mautic to docroot if it's not present
if ! [ -e index.php -a -e app/AppKernel.php ]; then
  echo >&2 "Mautic not found in $(pwd) - copying now..."

  tar cf - --one-file-system -C /usr/src/mautic . | tar xf -

  echo >&2 "Apply file permissions"
  chown -R $user:$group $docroot

  echo >&2 "Make bin dir contents executable"
  chmod a+x $docroot/bin/*

  echo >&2 "Complete! Mautic has been successfully copied to $(pwd)"
fi


# Assume fresh container if there is no local config file
if [ ! -f "$docroot/app/config/local.php" ]; then
  echo "No local.php file found in docroot.. Assume this is a fresh container."

  echo "Stat data dir outside volume"
  mkdir -p $dataroot

  echo "Apply permissions to dataroot"
  chown $user:$group $dataroot

  echo "Stat config dir"
  mkdir -p $dataroot/app/config

  echo "Make data dir writable"
  chmod ug+rwx $dataroot
fi


# Stat local config file
if [[ -f "$dataroot/app/config/local.php" && ! -L $docroot/app/config/local.php ]]; then
  echo "Symlink the local.php config file from volume to docroot"

  rm -rf $docroot/app/config/local.php
  ln -s $dataroot/app/config/local.php $docroot/app/config/local.php
  chown $user:$group $dataroot/app/config/local.php
  chmod ug+w $dataroot/app/config/local.php
fi


# Stat media dir
if [ ! -L "$docroot/media" ]; then
  echo "Stat media dir in volume"

  if [ -d "$docroot/media" ]; then
    cp -a -n $docroot/media $dataroot/
    chown $user:$group $dataroot/media
  fi

  if [ -d "$dataroot/media" ]; then
    rm -rf $docroot/media
    ln -s $dataroot/media $docroot/media
  fi
fi


# Stat translations dir
if [ ! -L "$docroot/translations" ]; then
  echo "Stat translations dir in volume"

  if [ -d "$docroot/translations" ]; then
    cp -a -n $docroot/translations $dataroot/
    chown $user:$group $dataroot/translations
  fi

  if [ -d "$dataroot/translations" ]; then
    rm -rf $docroot/translations
    ln -s $dataroot/translations $docroot/translations
  fi
fi


# Stat logs dir
if [ ! -L "$docroot/var/logs" ]; then
  echo "Stat var/logs dir in volume"

  if [ -d "$docroot/var/logs" ]; then
    cp -a -n $docroot/var/logs $dataroot/var/
    chown $user:$group $dataroot/var/logs
  fi

  if [ -d "$dataroot/var/logs" ]; then
    rm -rf $docroot/var/logs
    ln -s $dataroot/var/logs $docroot/var/logs
  fi
fi


# Stat spool dir
if [ ! -L "$docroot/var/spool" ]; then
  echo "Stat var/spool dir in volume"

  if [ -d "$docroot/var/spool" ]; then
    cp -a -n $docroot/var/spool $dataroot/var/
    chown $user:$group $dataroot/var/spool
  fi

  if [ -d "$dataroot/var/spool" ]; then
    rm -rf $docroot/var/spool
    ln -s $dataroot/var/spool $docroot/var/spool
  fi
fi


# Application runtime env
echo "APP_ENV = [${APP_ENV}]"

exec "$@"
