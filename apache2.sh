#!/bin/bash
function checkAndInstallApache2() {
  local APACHE2INSSTATUS = $(dpkg -s apache2 | grep Status:)
  if [ $APACHE2INSSTATUS == *"install ok installed"* ]; then
    local APACHE2RUNNINGSTATUS = $(systemctl status apache2 | grep Active:)
    if [ $APACHE2RUNNINGSTATUS == *"active"* ]; then
      echo "apache2 server already found and running, skip installing..."
    else 
      echo "ERROR: apache2 server already found, but is not running, please start and relaunch the script"
      return 2
    fi
  else
    sudo apt -y update
    sudo apt install -y apache2
    return 0;
  fi  
}

function cloneSite() {
  TODAY=$(date + “%Y/%m/%d-%H:%M:%S”)
  if [ -d /var/www/$PROJECTDIR ]; then
    mv /var/www/$PROJECTDIR /var/www/$PROJECTDIR_$TODAY
  fi
  cd /var/www
  sudo git clone -b master $GITREPO
  sudo chmod -R 755 /var/www/$PROJECTDIR    
  return 0
}

function configureAndEnableSite() {
  if [ -f /etc/apache2/sites-available/$PROJECTDIR.conf ]; then
    echo "site config found skipping...."
  else
    sudo cp siteconfig-template.conf /etc/apache2/sites-available/$PROJECTDIR.conf
    sed -i 's/#SERVERNAME#/$DOMAIN/g' /etc/apache2/sites-available/$PROJECTDIR.conf
    sed -i 's/#DOCUMENTROOT$/"/var/www/$PROJECTDIR"/g' /etc/apache2/sites-available/$PROJECTDIR.conf
    sudo a2ensite $PROJECTDIR
  fi
}

Function ReloadApache2(){
  sudo systemctl reload apache2
  RELOADSTATUS=$?
  exit $RELOADSTATUS
}

// main block
N_ARGS=$#
if [ $N_ARGS -ne 3 ]; then
  echo "ERROR: missing required 3 arguments"
  exit 1
fi
GITREPO=$1
DOMAIN=$2
PROJECTDIR=$3

checkAndInstallApache2
APACHE2STATUS=$?
if [ $APACHE2STATUS -ne 0 ]; then
  echo “ERROR : while Installing Apache2 server”
  exit $APACHE2STATUS  
fi

cloneSite
CLONESITESTATUS=$?
If [ $CLONESITESTATUS -ne 0 ]; then
  echo “ERROR : while cloning the site…”
  exit $CLONESITESTATUS 
fi
configureAndEnableSite 
CONFIGURESTATUS=$?
If [ $CONFIGURESTATUS -ne 0 ]; then
  echo “ERROR : while Configuring the apache site”
  exit $CONFIGURESTATUS 
fi
ReloadApache2
APACHERELOADSTATUS=$?
If [ APACHERELOADSTATUS -ne 0 ]; then
  echo “ERROR : While Reloading Apache2 server”
fi
