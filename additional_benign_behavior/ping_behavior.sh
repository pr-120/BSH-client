#!/bin/bash

CURR_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

while true; do
	
	for line in $(cat "$CURR_DIR/link_file.txt"); do
		# send requests to sites to simulate network usage
		echo "pinging $line..."
		curl -s "$line" > /dev/null
		sleep 0.3
	done
	
	# sleep for a random time to simulate irregular processes
	sleeptime=$((1 + $RANDOM % 100))
	echo "sleep for $sleeptime seconds"
	sleep $sleeptime
done
