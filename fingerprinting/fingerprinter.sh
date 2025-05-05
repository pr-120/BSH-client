#!/bin/bash -u

# adjust script configuration to match your use-case
# run with: nohup ./fingerprinter.sh 2>&1 & disown

##############################################################
#############		SCRIPT CONFIGURATION		##############
##############################################################
# C2 server and port to push data
server="192.168.189.10"
port="5000"
route="/fp/"
mac=$( cat /sys/class/net/eth0/address | tr : _ ) # find MAC address and replace ":" with "_" for usage in route

# remove finished flag
rm -f /home/admin/BA/config/fp_done.flag

#	Temperature monitoring
temperatureMonitor=true
#	Resource monitoring
resourceMonitor=true
# Time window per sample
timeWindowSeconds=5

##############################################################
############# 		GLOBALS 	  ##############
##############################################################
#	Set language to make sure same separator (, and .) config is being used
export LC_ALL=C.UTF-8
#	Events to monitor using perf
targetEvents="alarmtimer:alarmtimer_fired,alarmtimer:alarmtimer_start,block:block_bio_backmerge,block:block_bio_remap,block:block_dirty_buffer,block:block_getrq,block:block_touch_buffer,block:block_unplug,clk:clk_set_rate,cpu-migrations,cs,dma_fence:dma_fence_init,fib:fib_table_lookup,filemap:mm_filemap_add_to_page_cache,gpio:gpio_value,ipi:ipi_raise,irq:irq_handler_entry,irq:softirq_entry,jbd2:jbd2_handle_start,jbd2:jbd2_start_commit,kmem:kfree,kmem:kmalloc,kmem:kmem_cache_alloc,kmem:kmem_cache_free,kmem:mm_page_alloc,kmem:mm_page_alloc_zone_locked,kmem:mm_page_free,kmem:mm_page_pcpu_drain,mmc:mmc_request_start,net:net_dev_queue,net:net_dev_xmit,net:netif_rx,page-faults,pagemap:mm_lru_insertion,qdisc:qdisc_dequeue,qdisc:qdisc_dequeue,raw_syscalls:sys_enter,raw_syscalls:sys_exit,rpm:rpm_resume,rpm:rpm_suspend,sched:sched_process_exec,sched:sched_process_free,sched:sched_process_wait,sched:sched_switch,sched:sched_wakeup,signal:signal_deliver,signal:signal_generate,skb:consume_skb,skb:consume_skb,skb:kfree_skb,skb:kfree_skb,skb:skb_copy_datagram_iovec,sock:inet_sock_set_state,task:task_newtask,tcp:tcp_destroy_sock,tcp:tcp_probe,timer:hrtimer_start,timer:timer_start,udp:udp_fail_queue_rcv_skb,workqueue:workqueue_activate_work"
#	Initialize total time monitored (NOT TAKING INTO CONSIDERATION TIME BETWEEN SCREENSHOTS)
timeAccumulative=0


##############################################################
############# 		DYNAMIC CONFIGURATION 	  ##############
##############################################################
help()
{
  echo "Usage: fingerprinter.sh [ -n limit ]
                [ -h ]"
  exit 1
}

limited=false
limit=1
current=0

while getopts h:n: opt
do
  case $opt in
    n)
      limit=$OPTARG
      limited=true
      ;;
    \? | h)
      help
      ;;
  esac
done


##############################################################
#############     MONITORING LOOP			##############
##############################################################
lastRate="0" # initialize for loop-usage below
while [ "$current" -lt "$limit" ]
do
	##############################################################
	#############		   DATA COLLECTION			##############
	##############################################################
	#	Internet connection check via ping
	if ping -q -c 1 -W 1.5 8.8.8.8 >/dev/null; then
		connectivity="1"
	else
		connectivity="0"
	fi
	timestamp=$(($(date +%s%N)/1000000))

	#	First capture for network resources, results will be calculated as the difference between this capture and the one taken later
	#if [ "$resourceMonitor" = true ]
	#then
		#oldNetworkTraffic=$(ifconfig | grep -oP -e "bytes \K\w+" | head -n 4)
	#fi

	#	Perf will monitor the events and also act as a "sleep" between both network captures
	tempOutput=$( perf stat --log-fd 1 -e "$targetEvents" -a sleep "$timeWindowSeconds" )
	#echo "$tempOutput"

	if [ "$resourceMonitor" = true ]
	then
		#	capture of network resources
		networkStats=$(ifconfig | grep -oP -e "bytes \K\w+" | head -n 4)

		#	Capture with top for CPU usage, tasks, and RAM usage
		topResults=$(top -bn 2 -d 1)
	fi

	if [ "$temperatureMonitor" = true ]
	then
		#	Capture current CPU temperature as it may be responsible for throttling
		cpuTemperature=$(vcgencmd measure_temp)  # example "temp=80.6'C"
	fi

	##############################################################
	#############	DATA EXTRACTION/CALCULATION	  ##############
	##############################################################
	if [ "$resourceMonitor" = true ]
	then
		#	Network data fingerprint
		networkTraffic=$(echo "$networkStats" | paste -sd "," -)

		#	Data extraction from top results
		cpuSamples=$(echo "$topResults" | grep -i "^%Cpu(s):" | tail -n 1 | tr -s " " | tr "," "." | cut -d " " -f 2,4,6,8,10,12,14 --output-delimiter=",")
		taskSamples=$(echo "$topResults" | grep -i tasks | tail -n 1 | tr -s " " | cut -d " " -f 2,4,6,8,10 --output-delimiter=",")
		ramSamples=$(echo "$topResults" | grep -i "mib mem" | tail -n 1 | tr -s " " | cut -d " " -f 6,8,10 --output-delimiter=",")
		swapSamples=$(echo "$topResults" | grep -i "mib swap" | tail -n 1 | tr -s " " | cut -d " " -f 9 --output-delimiter=",")

		resourceSample="${cpuSamples},${taskSamples},${ramSamples},${swapSamples},${networkTraffic},"
	else
		resourceSample=""
	fi

	if [ "$temperatureMonitor" = true ]
	then
		#	Extract CPU temperature
		temperatureSample="${cpuTemperature%\'*}" # retain part before '
		temperatureSample="${temperatureSample##*=}," # retain part after = and add a comma
	else
	  temperatureSample=""
	fi

	#	Data extraction from perf results
	sample=$(echo "$tempOutput" | cut -c -20 | tr -s " " | tail -n +4 | head -n -2 | tr "\n" "," | sed 's/ //g'| sed 's/.$//')
	seconds=$(echo "$tempOutput" | tr -s " " | cut -d " " -f 2 | tail -n 1 | tr "," ".")

	#	Cumulative sum of seconds calculation
	timeAccumulative=$(awk "BEGIN{ print $timeAccumulative + $seconds }")

	##############################################################
	#############			   OUTPUT				##############
	##############################################################

	#	PUSH to C2 server (and store locally)
	finalOutput="$timeAccumulative,$timestamp,$seconds,$connectivity,${resourceSample}${temperatureSample}$sample"
	dt=$(date +%Y-%m-%d_%H-%M-%S)
	#echo "CPU: ${cpuSamples}"
	#echo "tasks: ${taskSamples}"
	#echo "RAM: ${ramSamples}"
	#echo "Swap: ${swapSamples}"
	#echo "Network: ${networkTraffic}"
	echo "$dt"
	echo "$finalOutput" >> "fp-$dt.txt"
	newRate="$(cat ./rate.roar)"
	lastRate=$([ -z "$newRate" ] && echo "$lastRate" || echo "$newRate") # do not assign empty newRate
	# echo -e "\n-- $lastRate" >> "fp-$dt.txt" # -e enables backslash escapes
	res=$(curl -sk -X POST -d "{\"fp\":[$finalOutput], \"rate\":$lastRate}" -H "Content-Type: application/json" "$server:$port$route$mac")
	

  if [ "$limited" = true ]
  then
    ((current++))
  fi
  if [ "$current" -gt 0 ] && [ $(("$current"%10)) = 0 ]
  then
    echo "Sent $current fingerprints"
  fi
done

if [ "$limited" = true ]
then
  echo "Sent $current fingerprints in total"
 
  # create finish flag which signals that fp is finished
  echo "fp finished successfully" > /home/admin/BA/config/fp_done.flag
fi


