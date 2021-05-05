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

    # create asserts
    # ---------------------------
    if [ -d "asserts" ]
    then
        echo "asserts directory already exists."
    else
        rm -rf asserts
        mkdir asserts
        echo "'asserts' directory created"
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
        composer install --optimize-autoloader --no-dev
    fi
    

    # We need to call php artisan
    # ----------------------------------------
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    echo "Done for php artisan config/route/view cache"

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
        rm -rf releases/$NOW/storage/app/public && ln -s ../../assets releases/$NOW/storage/app/public
    else
        ln -s ../../assets releases/$NOW/storage/app/public
    fi
    echo "Done for sharing assert"

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