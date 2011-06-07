#!/bin/sh

source $APPLICATION_DIR/env

if [ -z \$1 ];
then
   echo "no script name given"
fi

cat scripts/login.st \$1 | su -m $GEMSTONE_USER -c \"$GEMSTONE/bin/topaz -ql -T200000\"
