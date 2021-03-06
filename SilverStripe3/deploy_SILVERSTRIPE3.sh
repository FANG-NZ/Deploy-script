#!/bin/bash

#
# SilverStripe V3
# This script runs the custom deploy for a SILVERSTRIPE3 GIT project and 
# target environment.
#
# author: FANG F

###### DECLARATIONS ######
DEPLOY=1
BUILD=0
SHOW=1

KEEP_RELEASE_COUNT=3


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

    # create asserts
    # ---------------------------
    if [ -d "assets" ]
    then
        echo "assets directory already exists."
    else
        rm -rf assets
        mkdir assets
        echo "'assets' directory created"
    fi

    # ensure log and config files exist
	# ----------------------------------
	touch silverstripe.log
	touch _ss_environment.php
	echo "Build complete."
}


# ------------------------------------------------
# FUNCTION
# deploy
# ------------------------------------------------
deploy()
{
    # Create NOW
	# ----------------------------
  	NOW=$(date +"%Y%m%d%H%M%S")
  	echo "Deploying..."

    if [ -z $GIT_REMOTE ]
  	then
        echo "GIT_REMOTE not set. Deploy cancelled."
        exit 0
  	fi

  	if [ -z $GIT_TREEISH ]
  	then
        echo "GIT_TREEISH not set. Deploy cancelled."
        exit 0
  	fi

    echo "Git remote: '$GIT_REMOTE'"
  	echo "Git tree: '$GIT_TREEISH'"
  	echo "Destination: 'releases/$NOW'"

    mkdir releases/$NOW
    git clone --branch $GIT_TREEISH $GIT_REMOTE releases/$NOW

    if [ $? -eq 0 ]
  	then
        echo "git clone successful."
  	else
        echo "git clone DID NOT complete successfully."
        exit 0
  	fi

    
    # START enable SSL
    if [ $ENABLE_SSL = "true" ]
    then
        # If htaccess exists, remove it
        if [ -f "releases/$NOW/.htaccess" ]
        then
            rm releases/$NOW/.htaccess
        fi

        ln -s ../../.htaccess releases/$NOW/.htaccess
        echo "Replace htaccess successful."
    fi

    


    # Create current link to the latest 
    if [ -h "current" ]
    then
        rm current && ln -s releases/$NOW current    
    else
        ln -s releases/$NOW current    
    fi
    echo "Export successful. Repointing current to releases/$NOW"

    # Remove & create link for _ss_environment.php config file
    # ----------------------------------------
    ln -s ../../_ss_environment.php releases/$NOW/_ss_environment.php

    # removes any existing assets from deploy! 
	# (so we can share assets across deploys)
	# -----------------------------------------------
    if [ -d "releases/$NOW/assets" ]
    then
        rm -rf releases/$NOW/assets && ln -s ../../assets releases/$NOW/assets
    else
        ln -s ../../assets releases/$NOW/assets
    fi
    echo "Done for sharing assets"

    purge
    showall

    echo "Deploy complete. Current web site is now releases/$NOW"
}



# ------------------------------------------------
# FUNCTION
# This is to keep the latest version of deploy
# ------------------------------------------------
purge()
{
	echo "Removing all but the latest $KEEP_RELEASE_COUNT releases..."
	# reverse directory listing with newline
	# --------------------------------------
  	array=(`ls -1 -r releases/`) 
  	len=${#array[*]}
  	if [ $len -le $KEEP_RELEASE_COUNT ]
  	then
    		echo "...nothing to remove."
  	fi

  	i=0
  	while [ $i -lt $len ]; do

   		# echo "$i: ${array[$i]}"
		# -------------------------
   		if [ $i -gt $[$KEEP_RELEASE_COUNT-1] ]
   		then
     			echo "Removing $[$i+1] of $len ${array[$i]}"
     			rm -rf releases/${array[$i]}
   		fi
   		let i++

  	done
  	echo ""
}


# ------------------------------------------------
# FUNCTION
# This is to list all releases 
# ------------------------------------------------
showall()
{
    echo "Listing all releases..."
    array=(`ls -1 -r releases/`) #reverse directory listing with newline
    len=${#array[*]}

    i=0
    while [ $i -lt $len ]; do
        mydate="${array[$i]}"
        nice=`date +%c -d "${mydate:0:4}-${mydate:4:2}-${mydate:6:2} ${mydate:8:2}:${mydate:10:2}:${mydate:12:2}"`
        echo "releases/${array[$i]}: $nice"
        let i++
    done

    ls -l current
    echo ""
}



# ------------------------------------------------
# FUNCTION
# Parse options
# ------------------------------------------------
parseopts () {
    while getopts "bs" optname
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

                "s" )
                    BUILD=0
       		        DEPLOY=0;;
       	
            esac
        done
}


parseopts "$@"

# Try to load Deploy Config file
# ---------------------------------------------------
if [ ! -f ./deploy.conf ]
then
  echo "Configuration file deploy.conf not found. Exiting."
  exit 0
fi
# import DEPLOY CONFIG file
# ----------------------------------------------------
source ./deploy.conf


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

# Handle SHOW ALL
# ----------------------------------
if [ $SHOW -eq 1 ]
then
  showall
  exit 0
fi