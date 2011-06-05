# check existance of a file and exit if it does not exist
function check_file {
   if [ ! -f "$1" ]; 
   then
      echo "file $1 does not exist"
      exit 1
   fi	
}

# check that a given parameter is not of zero size. Exit if it is missing
function mandatory_parameter {
   if [ -z ${!1} ]; 
   then
      #echo "mandatory parameter $1 does not exist"
      help;
      exit 1
   fi	
}

# check if a file exists and load/evaluate it
function load {
   check_file $1;
   source $1
}

# create directory
function createDirectory {
   if [ ! -d $1 ];
   then
      mkdir $1 2>/dev/null
   fi
}

# read a file evaluate every expression and write it back to another file
function evalAndWriteTo {
   eval "echo \"$(< $1 )\"" > $2
}
