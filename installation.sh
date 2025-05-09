#!/bin/bash

#load folder paths of application
. ./config/folder_paths.config


# install virtual environment for openSenseMap functionality
python -m venv $openSenseMap_folder/.venv
source $openSenseMap_folder/.venv/bin/activate
pip install -r $openSenseMap_folder/requirements.txt
deactivate

# install needed system packages
sudo apt-get install libcurl4-openssl-dev
sudo apt-get install scren
sudo apt-get install libcjson-dev

# compile backdoor
cd $tick_backdoor_folder/src
make clean
make


# install packages for sensor
sudo apt-get install i2c-tools
