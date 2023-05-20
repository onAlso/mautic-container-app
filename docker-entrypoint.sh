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


# Entry point log
logfile=/home/LogFiles/entrypoint.log
test ! -f $logfile && mkdir -p /home/LogFiles && touch $logfile
exec > >(log | tee -ai $logfile)
exec 2>&1


# Cron logs
cronlogfile=/home/LogFiles/mautic_cron.log
test ! -f $cronlogfile && mkdir -p /home/LogFiles && touch $cronlogfile
chown $user:$group $cronlogfile
chmod a+r $cronlogfile


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

  echo "Apply file permissions"
  chown -R $user:$group $dataroot

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
    chown -R $user:$group $dataroot/media
    chmod -R ug+w $dataroot/media
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
    chown -R $user:$group $dataroot/translations
    chmod -R ug+w $dataroot/translations
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
    chown -R $user:$group $dataroot/var/logs
    chmod -R ug+w $dataroot/var/logs
  fi

  if [ -d "$dataroot/logs" ]; then
    rm -rf $docroot/var/logs
    ln -s $dataroot/var/logs $docroot/var/logs
  fi
fi


# Stat spool dir
if [ ! -L "$docroot/var/spool" ]; then
  echo "Stat var/spool dir in volume"

  if [ -d "$docroot/var/spool" ]; then
    cp -a -n $docroot/var/spool $dataroot/var/
    chown -R $user:$group $dataroot/var/spool
    chmod -R ug+w $dataroot/var/spool
  fi

  if [ -d "$dataroot/spool" ]; then
    rm -rf $docroot/var/spool
    ln -s $dataroot/var/spool $docroot/var/spool
  fi
fi


# Application runtime env
echo "APP_ENV = [${APP_ENV}]"

exec "$@"
