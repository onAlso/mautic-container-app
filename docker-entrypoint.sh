#!/bin/bash
log(){
	while read line ; do
		echo "`date '+%D %T'` $line"
	done
}

set -e
user="${APACHE_RUN_USER:-www-data}"
group="${APACHE_RUN_GROUP:-www-data}"
docroot="/var/www/docroot"
datadir="/var/www/data"


# Copy over Mautic to docroot if it's not present
if ! [ -e "$docroot/index.php" -a -e "$docroot/app/AppKernel.php" ]; then
  echo >&2 "Mautic not found in $(pwd) - Killing..."
  exit 2
fi


# Assume fresh container if there is no local config file
if [ ! -f "$docroot/app/config/local.php" ]; then
  echo "No local.php file found in docroot.. Assume this is a fresh container."

  echo "Stat data dir outside volume"
  mkdir -p $datadir

  echo "Stat config dir"
  mkdir -p $datadir/app/config

  echo >&2 "Apply file permissions"
  chown -R $user:$group $docroot
  chown -R $user:$group $datadir
  chmod -R ug+rwx $datadir
  chmod a+x bin/*
fi


# Stat local config file
if [[ -f "$datadir/app/config/local.php" && ! -L $docroot/app/config/local.php ]]; then
  echo "Symlink the local.php config file from datadir to docroot"

  rm -rf $docroot/app/config/local.php
  ln -s $datadir/app/config/local.php $docroot/app/config/local.php
  chown $user:$group $datadir/app/config/local.php
  chmod ug+w $datadir/app/config/local.php
fi


# Copy custom favicon
if [ -f "$datadir/favicon.ico" ]; then
  echo "Copy custom favicon from datadir to docroot"

  cp -a -f $datadir/favicon.ico $docroot/favicon.ico
  chown $user:$group $docroot/favicon.ico
fi


# Copy custom themes
if [ -d "$datadir/themes" ]; then
  echo "Copy custom themes from datadir to docroot"

  cp -a $datadir/themes/* $docroot/themes/
  chown -R $user:$group $docroot/themes
fi


# Copy custom plugins
if [ -d "$datadir/plugins" ]; then
  echo "Copy custom plugins from datadir to docroot"

  cp -a $datadir/plugins/* $docroot/plugins/
  chown -R $user:$group $docroot/plugins
fi


# Stat media dir
if [ ! -L "$docroot/media" ]; then
  echo "Stat media dir in volume"

  if [ -d "$docroot/media" ]; then
    cp -a -n $docroot/media $datadir/
  fi

  if [ -d "$datadir/media" ]; then
    rm -rf $docroot/media
    ln -s $datadir/media $docroot/media
  fi
fi


# Stat translations dir
if [ ! -L "$docroot/translations" ]; then
  echo "Stat translations dir in volume"

  if [ -d "$docroot/translations" ]; then
    cp -a -n $docroot/translations $datadir/
  fi

  if [ -d "$datadir/translations" ]; then
    rm -rf $docroot/translations
    ln -s $datadir/translations $docroot/translations
  fi
fi


# Stat logs dir
if [ ! -L "$docroot/var/logs" ]; then
  echo "Stat var/logs dir in volume"

  if [ -d "$docroot/var/logs" ]; then
    mkdir -p $datadir/var/logs
    chown $user:$group $datadir/var/logs
    cp -a -n $docroot/var/logs $datadir/var/logs
  fi

  if [ -d "$datadir/var/logs" ]; then
    mkdir -p $docroot/var/
    chown -R $user:$group $docroot/var/
    rm -rf $docroot/var/logs
    ln -s $datadir/var/logs $docroot/var/logs
  fi
fi


# Stat spool dir
if [ ! -L "$docroot/var/spool" ]; then
  echo "Stat var/spool dir in volume"

  if [ -d "$docroot/var/spool" ]; then
    mkdir -p $datadir/var/spool
    chown $user:$group $datadir/var/spool
    cp -a -n $docroot/var/spool $datadir/var/
  fi

  if [ -d "$datadir/var/spool" ]; then
    mkdir -p $docroot/var/
    chown -R $user:$group $docroot/var/
    rm -rf $docroot/var/spool
    ln -s $datadir/var/spool $docroot/var/spool
  fi
fi


# Application runtime env
echo "APP_ENV = [${APP_ENV}]"

exec "$@"
