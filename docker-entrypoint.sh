#!/bin/bash
log(){
	while read line ; do
		echo "`date '+%D %T'` $line"
	done
}

set -e
user="${APACHE_RUN_USER:-www-data}"
group="${APACHE_RUN_GROUP:-www-data}"
htmldir="/var/www/html"
datadir="/var/www/data"


# Copy over Mautic to htmldir if it's not present
if ! [ -e "$htmldir/docroot/index.php" -a -e "$htmldir/docroot/app/AppKernel.php" ]; then
  echo >&2 "Mautic not found in $(pwd) - copying now..."

  tar cf - --one-file-system -C /usr/src/mautic . | tar xf -

  echo >&2 "Apply file permissions"
  chown -R $user:$group $htmldir
  chmod a+x $htmldir/bin/*
fi


# Assume fresh container if there is no local config file
if [ ! -f "$htmldir/docroot/app/config/local.php" ]; then
  echo "No local.php file found in docroot.. Assume this is a fresh container."

  echo "Stat data dir outside volume"
  mkdir -p $datadir

  echo "Stat config dir"
  mkdir -p $datadir/app/config

  echo >&2 "Apply file permissions"
  chown -R $user:$group $datadir/app/config
  chmod -R ug+rwx $datadir/app/config
fi


# Stat local config file
if [[ -f "$datadir/app/config/local.php" && ! -L $htmldir/docroot/app/config/local.php ]]; then
  echo "Symlink the local.php config file from datadir to docroot"

  rm -rf $htmldir/docroot/app/config/local.php
  ln -s $datadir/app/config/local.php $htmldir/docroot/app/config/local.php
  chown $user:$group $datadir/app/config/local.php
  chmod ug+w $datadir/app/config/local.php
fi


# Copy custom favicon
if [ -f "$datadir/favicon.ico" ]; then
  echo "Copy custom favicon from datadir to docroot"

  cp -a -f $datadir/favicon.ico $htmldir/docroot/favicon.ico
  chown $user:$group $htmldir/docroot/favicon.ico
fi


# Copy custom themes
if [ -d "$datadir/themes" ]; then
  echo "Copy custom themes from datadir to docroot"

  cp -a $datadir/themes/* $htmldir/docroot/themes/
  chown -R $user:$group $htmldir/docroot/themes
fi


# Copy custom plugins
if [ -d "$datadir/plugins" ]; then
  echo "Copy custom plugins from datadir to docroot"

  cp -a $datadir/plugins/* $htmldir/docroot/plugins/
  chown -R $user:$group $htmldir/docroot/plugins
fi


# Stat media dir
if [ ! -L "$htmldir/docroot/media" ]; then
  echo "Stat media dir in volume"

  if [ -d "$htmldir/docroot/media" ]; then
    cp -a -n $htmldir/docroot/media $datadir/
  fi

  if [ -d "$datadir/media" ]; then
    rm -rf $htmldir/docroot/media
    ln -s $datadir/media $htmldir/docroot/media
  fi
fi


# Stat translations dir
if [ ! -L "$htmldir/docroot/translations" ]; then
  echo "Stat translations dir in volume"

  if [ -d "$htmldir/docroot/translations" ]; then
    cp -a -n $htmldir/docroot/translations $datadir/
  fi

  if [ -d "$datadir/translations" ]; then
    rm -rf $htmldir/docroot/translations
    ln -s $datadir/translations $htmldir/docroot/translations
  fi
fi


# Stat var dir
if [ ! -d "$htmldir/docroot/var" ]; then
  echo "Stat var dir in docroot"
  mkdir -p $htmldir/docroot/var/cache
  mkdir -p $htmldir/docroot/var/tmp
  mkdir -p $datadir/var/logs
  mkdir -p $datadir/var/spool

  echo >&2 "Apply file permissions"
  chown -R $user:$group $htmldir/docroot/var
  chown $user:$group $datadir/var/logs
  chown $user:$group $datadir/var/spool
fi

# Stat logs dir
if [ ! -L "$htmldir/docroot/var/logs" ]; then
  echo "Stat var/logs dir in volume"

  if [ -d "$htmldir/docroot/var/logs" ]; then
    cp -a -n $htmldir/docroot/var/logs $datadir/var/
  fi

  if [ -d "$datadir/var/logs" ]; then
    rm -rf $htmldir/docroot/var/logs
    ln -s $datadir/var/logs $htmldir/docroot/var/logs
  fi
fi


# Stat spool dir
if [ ! -L "$htmldir/docroot/var/spool" ]; then
  echo "Stat var/spool dir in volume"

  if [ -d "$htmldir/docroot/var/spool" ]; then
    cp -a -n $htmldir/docroot/var/spool $datadir/var/
  fi

  if [ -d "$datadir/var/spool" ]; then
    rm -rf $htmldir/docroot/var/spool
    ln -s $datadir/var/spool $htmldir/docroot/var/spool
  fi
fi


# Application runtime env
echo "APP_ENV = [${APP_ENV}]"

exec "$@"
