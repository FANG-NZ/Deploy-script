#!/bin/bash

#
# This script runs the custom deploy for a LARAVEL GIT project and 
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

    # create assets
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

    cd releases/$NOW
    # Composer install & setup

    if [ $ENV = "dev" ]
    then
        # FOR DEV
        # This is for my MAC OS, we need to find another way to 
        # fix it
        # MacOS can't use alisa in script
        php /usr/local/bin/composer.phar install
    else
        # FOR LIVE
        composer install --optimize-autoloader
    fi
    

    # We need to call php artisan
    # ----------------------------------------
    #php artisan config:cache
    #php artisan route:cache
    #php artisan view:cache
    php artisan storage:link
    chmod 777 -R storage

    # Install NPM & setup
    npm install 
    npm run prod
    echo "Done for NPM setup"
    cd ../../

    # Create current link to the latest 
    if [ -h "current" ]
    then
        rm current && ln -s releases/$NOW/public current    
    else
        ln -s releases/$NOW/public current    
    fi

    # Remove & create link for .env config file
    # ----------------------------------------
    ln -s ../../.env releases/$NOW/.env

    echo "Export successful. Repointing current to releases/$NOW"

    # removes any existing assets from deploy! 
	# (so we can share assets across deploys)
	# -----------------------------------------------
    if [ -d "releases/$NOW/storage/app/public" ]
    then
        rm -rf releases/$NOW/storage/app/public && ln -s ../../../../assets releases/$NOW/storage/app/public
    else
        ln -s ../../../../assets releases/$NOW/storage/app/public
    fi
    echo "Done for sharing assets"

    # remove log file and create link
    # -----------------------------------------------
    if [ -f "releases/$NOW/storage/logs/laravel.log" ]
    then
        rm -rf releases/$NOW/storage/logs/laravel.log && ln -s ../../../../laravel.log releases/$NOW/storage/logs/laravel.log
    else
        ln -s ../../../../laravel.log releases/$NOW/storage/logs/laravel.log
    fi
    echo "Done for link log file"

    # update site cache & config
    php releases/$NOW/artisan optimize
    echo "Done for site config & setup"

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