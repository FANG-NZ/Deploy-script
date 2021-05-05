#!/bin/bash

#
# This script runs the custom deploy for a LARAVEL GIT project and 
# target environment.
#
# author: FANG F

###### DECLARATIONS ######
DEPLOY=1
BUILD=0


# ------------------------------------------------
# FUNCTION
# Building folder structure
# ------------------------------------------------
build()
{
    echo "Building deploy file and folder structure..."

    # create releases directory
	# ---------------------------
	if [ -d "releases" ]
	then
		echo "releases directory already exists."
	else
		echo "releases directory does not exist or is not a directory."
		rm -rf releases
		mkdir releases
		echo "releases' directory created."
	fi

    # ensure log and config files exist
	# ----------------------------------
	touch laravel.log
	touch .env
	echo "Build complete."
}


# ------------------------------------------------
# FUNCTION
# deploy
# ------------------------------------------------
deploy()
{
    echo "TODO deploy"
}



# ------------------------------------------------
# FUNCTION
# Parse options
# ------------------------------------------------
parseopts () {
    while getopts "b" optname
        do
            case ${optname} in

    	        \? ) 
                    echo "Invalid option: - ${optname}" 1>&2
	                exit 1;;

                : ) 
                    echo "Option -$OPTARG requires an argument."
                    exit 1;;

                "b" ) 
                    BUILD=1
       		        DEPLOY=0;;
       	
            esac
        done
}


parseopts "$@"

# Handle BUILD
# ----------------------------------
if [ $BUILD -eq 1 ]
then
	build
    exit 0
fi

# Handle DEPLOY
# ----------------------------------
if [ $DEPLOY -eq 1 ]
then
  deploy
  exit 0
fi