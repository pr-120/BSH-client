#!/bin/bash

while true; do
	
	for line in $(cat "link_file.txt"); do
		# send requests to sites to simulate network usage
		curl -s "$line" > /dev/null
		sleep 0.3
	done
	
	# sleep for a random time to simulate irregular processes
	sleeptime=$((1 + $RANDOM % 100))
	echo "sleep for $sleeptime seconds"
	sleep $sleeptime
done
