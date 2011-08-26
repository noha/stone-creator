#!/bin/sh

while getopts ":d:g:f:r" opt; do
  case $opt in
    d)
      DATA_DIR=$OPTARG
      ;;
    f)
      FILE=$OPTARG
      ;;
    g)
      export GEMSTONE=$OPTARG
      ;;
    r)
      REMOVE_TRANLOGS=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

function help {
   echo "usage: $0 -d [directory] -g [gemstonedir] -r"
   echo "
   -d [directory]   data directory of stone (containing extent0.dbf)
   -f [file]        file to take information about needed tranlog from (extent or backup)
   -g [gemstonedir] directory of gemstone installation (default: /opt/gemstone/product)
   -r               really remove tranlogs. Without this switch they are only shown
"
   exit
}

if [ "$DATA_DIR" == "" ];
then
	help;
fi


if [ ! -f "$FILE" ];
then
   echo "did not find $FILE"
   exit
fi

if [ "$GEMSTONE" == "" ];
then
   COPYDBF_EXE=`which copydbf`
else
   COPYDBF_EXE="$GEMSTONE/bin/copydbf"
fi

if [ ! -x "$COPYDBF_EXE" ];
then
   echo "cannot find copydbf binary. please use -e argument or adjust your path variable"
   exit
fi

LAST_NEEDED_TRANLOG=`$COPYDBF_EXE -i $FILE 2>&1 | grep tranlog | cut -d ' ' -f 13`

if [ "$LAST_NEEDED_TRANLOG" == "" ];
then
   echo "could not find information about last needed tranlog"
   exit
fi

if [[ ! "$LAST_NEEDED_TRANLOG" =~ tranlog[0-9][0-9]*.dbf$ ]];
then
   echo "parse error in output from copydby. Result is not a tranlog filename"
   exit
fi

SORTED_LIST_OF_FILES=`ls -1 $DATA_DIR/tranlog* | xargs -n1 basename | sort -k2 -tg -n`
LINES_IN_LIST=`echo "$SORTED_LIST_OF_FILES" | wc -l`

if [ "$LINES_IN_LIST" -eq 1 ];
then
   echo "only one tranlog file found. nothing to delete"
   exit
fi

LINE_OF_LAST_NEEDED_TRANLOG=`echo "$SORTED_LIST_OF_FILES" | grep -n $LAST_NEEDED_TRANLOG | cut -d ':' -f 1`

if [ "$LINE_OF_LAST_NEEDED_TRANLOG" == "" ];
then
   echo "could not find last needed tranlog in list of available tranlogs."
   exit
fi

if [ "$LINE_OF_LAST_NEEDED_TRANLOG" -lt 2 ];
then
   echo "nothing to do"
   exit
fi

LINE_OF_LAST_OBSOLETE_FILE=$(($LINE_OF_LAST_NEEDED_TRANLOG -1 ))

for obsolete in `echo "$SORTED_LIST_OF_FILES" | head -n $LINE_OF_LAST_OBSOLETE_FILE`;
do
   if [ ! -z "$REMOVE_TRANLOGS" ];
   then
      echo "removing $obsolete"
      rm "$DATA_DIR/$obsolete"
   else
      echo "file $obsolete is obsolete"
   fi
done
