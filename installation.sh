#!/bin/bash

##### CONFIG #############################

# folder path of current file
SCRIPT_DIR="$(dirname "$BASH_SOURCE[0]}")"

#load folder paths of application
. $SCRIPT_DIR/config/folder_paths.config

##########################################

# exclude config file from git pull, otherwise default values are restored
git update-index --assume-unchanged $SCRIPT_DIR/config/app_data.config

# install virtual environment for openSenseMap functionality
python -m venv $openSenseMap_folder/.venv
source $openSenseMap_folder/.venv/bin/activate
pip install -r $openSenseMap_folder/requirements.txt
deactivate

# install needed system packages
packages=( "libcurl4-openssl-dev" "screen" "libcjson-dev" "linux-perf" )
for package in "${packages[@]}"; do
	sudo apt-get install $package
done

# compile backdoor
cd $tick_backdoor_folder/src
make clean
make


# install packages for sensor
sudo apt-get install i2c-tools

