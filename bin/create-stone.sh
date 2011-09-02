#!/bin/bash

#####
#
# create a skeleton in a directory to run a stone in
# 
#####

# unset variables to be safe if the environment has been sourced in the parent shell
unset APPLICATION_NAME
unset APPLICATION_DIR
unset GEMSTONE_USER

DIR=`dirname $0`
CREATOR_DIR="$DIR/../"
ETC_DIR="$DIR/../etc/"
LIB_DIR="$DIR"
SCRIPT_DIR="$DIR/../scripts"

source $LIB_DIR/functions.sh

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

###
# set defaults for parameters
###

GEMSTONE_USER=${GEMSTONE_USER:-gemstone}
SHARED_PAGE_CACHE_SIZE=${SHARED_PAGE_CACHE_SIZE:-100000}
TEMPORARY_OBJECT_MEMORY=${TEMPORARY_OBJECT_MEMORY:-50000}

###
# check mandatory parameters
###

mandatory_parameter APPLICATION_NAME
mandatory_parameter APPLICATION_DIR

###
# define template variables
###
APPLICATION_BIN_DIR=$APPLICATION_DIR/bin
APPLICATION_ETC_DIR=$APPLICATION_DIR/etc
APPLICATION_DATA_DIR=$APPLICATION_DIR/data
APPLICATION_LOG_DIR=$APPLICATION_DIR/log

###
# create application directory skeleton
####
createDirectory $APPLICATION_DIR
createDirectory $APPLICATION_DATA_DIR
createDirectory $APPLICATION_LOG_DIR
createDirectory $APPLICATION_ETC_DIR
createDirectory $APPLICATION_BIN_DIR
createDirectory $APPLICATION_DIR/scripts

###
# load configuration about gemstone installation
###

load $CREATOR_DIR/gemstone.conf

###
# if requested install a virgin seaside extent into the new application
###

if [ ! -z $FRESH_EXTENT ];
then
   echo "installing fresh extent"
   cp $GEMSTONE_INSTALLATION/bin/extent0.seaside.dbf $APPLICATION_DATA_DIR/extent0.dbf
   chmod +w $APPLICATION_DATA_DIR/extent0.dbf
   echo "removing old tranlogs"
   rm $APPLICATION_DATA_DIR/tranlog* 2>/dev/null
fi

###
# generate target environment and load it. All further script copies will
# replace the configuration templates with the real values
###

evalAndWriteTo $CREATOR_DIR/env $APPLICATION_DIR/env
source $APPLICATION_DIR/env

###
# write executable scripts to bin/
###

for i in runTopazScript.sh;
do
   evalAndWriteTo $DIR/$i $APPLICATION_BIN_DIR/$i
done

###
# write config files to etc/
###
for i in system.conf gem.conf;
do
   evalStripAndWriteTo $ETC_DIR/$i $APPLICATION_ETC_DIR/$i
done

###
# copy scripts to scripts/ 
###

for i in scripts/* ;
do
   SCRIPT=`basename $i`
   evalAndWriteTo $SCRIPT_DIR/$SCRIPT $APPLICATION_DIR/scripts/$SCRIPT
done

###
# generate a system V init script that can be linked into /etc/init.d
###

sed -e "s#\$STONE_ENV#$APPLICATION_DIR/env#" <  $CREATOR_DIR/start-stop-script > $APPLICATION_DIR/$APPLICATION_NAME
chmod +x $APPLICATION_DIR/$APPLICATION_NAME

evalAndWriteTo $ETC_DIR/topazini $APPLICATION_DIR/.topazini

###
# the script is supposed to be run by root or the same user as GEMSTONE_USER. 
###

if [ ! "`whoami`" == "$GEMSTONE_USER" ];
then
   chown -R $GEMSTONE_USER $APPLICATION_DIR
fi
