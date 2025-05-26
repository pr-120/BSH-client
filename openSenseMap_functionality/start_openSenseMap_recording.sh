#!/bin/bash

# load folder paths
. ./config/folder_paths.config

# activate virtual env
source $openSenseMap_folder/.venv/bin/activate

# start posting of environmental data to OpenSenseMap
python $openSenseMap_folder/main.py


