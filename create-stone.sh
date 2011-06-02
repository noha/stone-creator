#!/bin/bash

#####
# create a skeleton in a directory to run a stone in
# 
#####

# unset variables to be safe if the environment has been sourced in the parent shell
unset APPLICATION_NAME
unset APPLICATION_DIR
unset GEMSTONE_USER

DIR=`dirname $0`

source $DIR/functions.sh

function help {
   echo "usage: $0 -n [name] -d [directory] -f -u [runasuser] -s [spc size] -t [tempmem]"
   echo "
   -n [name]       name of the stone
   -d [directory]  directory to install the skeleton to
   -f              copy a virgin extent from the gemstone installation? 
   -u [runasuser]  system user to start to stone
                   default is: gemstone
   -s [spc size]   configure the stone to use [spc size] for the shared memory cache
                   The size is given as bytes
                   default is: 100000
   -t [tempmem]    The temporary object memory assigned to the stone
"
}

while getopts ":n:d:u:fs:t:" opt; do
  case $opt in
    n)
      APPLICATION_NAME=$OPTARG
      ;;
    d)
      APPLICATION_DIR=$OPTARG
      ;;
    f)
      FRESH_EXTENT=1
      ;;
    u)
      GEMSTONE_USER=$OPTARG
      ;;
    s)
      SHARED_PAGE_CACHE_SIZE=$OPTARG
      ;;
    t)
      TEMP_OBJECT_MEMORY=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

GEMSTONE_USER=${GEMSTONE_USER:-gemstone}
SHARED_PAGE_CACHE_SIZE=${SHARED_PAGE_CACHE_SIZE:-100000}
TEMPORARY_OBJECT_MEMORY=${TEMPORARY_OBJECT_MEMORY:-50000}

mandatory_parameter APPLICATION_NAME
mandatory_parameter APPLICATION_DIR
createDirectory $APPLICATION_DIR
createDirectory $APPLICATION_DIR/scripts

APPLICATION_DATA_DIR=$APPLICATION_DIR/data
createDirectory $APPLICATION_DATA_DIR

APPLICATION_LOG_DIR=$APPLICATION_DIR/log
createDirectory $APPLICATION_LOG_DIR

load $DIR/gemstone.conf

if [ ! -z $FRESH_EXTENT ];
then
   echo "installing fresh extent"
   cp $GEMSTONE_INSTALLATION/bin/extent0.seaside.dbf $APPLICATION_DATA_DIR/extent0.dbf
   chmod +w $APPLICATION_DATA_DIR/extent0.dbf
   echo "removing old tranlogs"
   rm $APPLICATION_DATA_DIR/tranlog* 2>/dev/null
fi

evalAndWriteTo $DIR/env $APPLICATION_DIR/env
source $APPLICATION_DIR/env

for i in env system.conf gem.conf run.sh login.st scripts/* ;
do
   evalAndWriteTo $DIR/$i $APPLICATION_DIR/$i
done

# generate a system V init script that can be linked into /etc/init.d
sed -e "s#\$STONE_ENV#$APPLICATION_DIR/env#" <  $DIR/start-stop-script > $APPLICATION_DIR/$APPLICATION_NAME
chmod +x $APPLICATION_DIR/$APPLICATION_NAME

evalAndWriteTo $DIR/topazini $APPLICATION_DIR/.topazini

# the script is supposed to be run by root or the same user as GEMSTONE_USER. 
if [ ! "`whoami`" == "$GEMSTONE_USER" ];
then
   chown -R $GEMSTONE_USER $APPLICATION_DIR
fi
