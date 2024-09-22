#!/bin/bash

# Start the disk usage monitoring in the background
while true; do
    clear
    df -ih
    sleep 5  # Adjust the sleep duration as needed
done &

# Store the background process ID
monitor_pid=$!

# Run the main script
./do_this.sh --auto --debug

# Terminate the monitoring process after the main script finishes
kill $monitor_pid
