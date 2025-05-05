#!/bin/bash

path_to_requirements="./requirements.txt"

# create and activate virtual environment
echo "activating env..."
python3 -m venv ./venv
source ./venv/bin/activate
echo "done"

while true; do

	# install requirements without caching
	echo "installing requirements..."
	pip install -r $path_to_requirements --no-cache-dir --quiet
	echo "done"
	
	# uninstall all packages
	echo "uninstalling everything except pip, setuptools and wheel..."
	pip freeze | grep -vE '^(pip|setuptools|wheel)==.*' | xargs pip uninstall -y --quiet
	echo "done"
 	
	# sleep for a random time to simulate irregular processes
	sleeptime=$((1 + $RANDOM % 100))
	echo "sleep for $sleeptime seconds"
	sleep $sleeptime
done
