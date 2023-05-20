#!/bin/bash
log(){
	while read line ; do
		echo "`date '+%D %T'` $line"
	done
}

set -e
logfile=/home/LogFiles/entrypoint.log
test ! -f $logfile && mkdir -p /home/LogFiles && touch $logfile
exec > >(log | tee -ai $logfile)
exec 2>&1

user="${APACHE_RUN_USER:-www-data}"
group="${APACHE_RUN_GROUP:-www-data}"
docroot="/var/www/docroot"
wwwroot="/home/site/wwwroot"

# Cron logs
cronlogfile=/home/LogFiles/mautic_cron.log
test ! -f $cronlogfile && mkdir -p /home/LogFiles && touch $cronlogfile
chown $user:$group $cronlogfile
chmod a+r $cronlogfile

# Verify wwwroot
echo "Stat app config dir in volume"
mkdir -p $wwwroot/app/config/

# Override local config if we have one in /var/www/local dir
if [ -f "/var/www/local/local.php" ]; then
  echo "Override current local.php config file from /var/www/local"
  cp -f /var/www/local/local.php $wwwroot/app/config/local.php
fi


# Assume fresh container if there is no local config file
if [ ! -f "$docroot/app/config/local.php" ]; then
  echo "No local.php file found in docroot.. Assume this is a fresh container."

  echo "Stat var dir outside volume"
  mkdir -p /var/www/var

  echo "Apply file permissions"
  chown -R $user:$group /var/www/var
  chown -R $user:$group $wwwroot
  chown -R $user:$group $docroot

  echo "Make var dir writable"
  chmod ug+rwx /var/www/var
  chmod a+x $docroot/bin/*
fi


# Stat local config file
if [[ -f "$wwwroot/app/config/local.php" && ! -L $docroot/app/config/local.php ]]; then
  echo "Symlink the local.php config file from volume to docroot"

  rm -rf $docroot/app/config/local.php
  ln -s $wwwroot/app/config/local.php $docroot/app/config/local.php
  chown $user:$group $wwwroot/app/config/local.php
  chmod ug+w $wwwroot/app/config/local.php
fi


# Stat media dir
if [ ! -L "$docroot/media" ]; then
  echo "Stat media dir in volume"

  if [ -d "$docroot/media" ]; then
    cp -a -n $docroot/media $wwwroot/
    chown -R $user:$group $wwwroot/media
    chmod -R ug+w $wwwroot/media
  fi

  if [ -d "$wwwroot/media" ]; then
    rm -rf $docroot/media
    ln -s $wwwroot/media $docroot/media
  fi
fi


# Stat plugins dir
if [ ! -L "$docroot/plugins" ]; then
  echo "Stat plugins dir in volume"

  if [ -d "$docroot/plugins" ]; then
    cp -a -n $docroot/plugins $wwwroot/
    chown -R $user:$group $wwwroot/plugins
    chmod -R ug+w $wwwroot/plugins
  fi

  if [ -d "$wwwroot/plugins" ]; then
    rm -rf $docroot/plugins
    ln -s $wwwroot/plugins $docroot/plugins
  fi
fi


# Stat themes dir
if [ ! -L "$docroot/themes" ]; then
  echo "Stat themes dir in volume"

  if [ -d "$docroot/themes" ]; then
    cp -a -n $docroot/themes $wwwroot/
    chown -R $user:$group $wwwroot/themes
    chmod -R ug+w $wwwroot/themes
  fi

  if [ -d "$wwwroot/themes" ]; then
    rm -rf $docroot/themes
    ln -s $wwwroot/themes $docroot/themes
  fi
fi


# Stat translations dir
if [ ! -L "$docroot/translations" ]; then
  echo "Stat translations dir in volume"

  if [ -d "$docroot/translations" ]; then
    cp -a -n $docroot/translations $wwwroot/
    chown -R $user:$group $wwwroot/translations
    chmod -R ug+w $wwwroot/translations
  fi

  if [ -d "$wwwroot/translations" ]; then
    rm -rf $docroot/translations
    ln -s $wwwroot/translations $docroot/translations
  fi
fi


# Stat var dir
if [ ! -L "$docroot/var" ]; then
  echo "Stat var dir in volume"

  if [ -d "$docroot/var" ]; then
    cp -a -n $docroot/var $wwwroot/
    chown -R $user:$group $wwwroot/var
    chmod -R ug+w $wwwroot/var
  fi

  if [ -d "$wwwroot/var" ]; then
    rm -rf $docroot/var
    ln -s $wwwroot/var $docroot/var
  fi
fi

# Start ssh server
echo "Starting sshd..."
service ssh start

# Start cron scheduler
echo "Starting cron..."
service cron start

# Application runtime env
echo "APP_ENV = [${APP_ENV}]"

exec "$@"
