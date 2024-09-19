#!/bin/bash

# Check if core range is provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: Core range not provided. Usage: $0 <start_core>-<end_core>"
    exit 1
fi

# Parse the core range from the command-line argument
IFS='-' read -ra CORE_ARRAY <<< "$1"
if [ ${#CORE_ARRAY[@]} -ne 2 ]; then
    echo "Error: Invalid core range format. Expected format: <start_core>-<end_core>"
    exit 1
fi

START_CORE=${CORE_ARRAY[0]}
END_CORE=${CORE_ARRAY[1]}

# Automatically detect the node binary
NODE_DIR="/root/ceremonyclient/node"
NODE_BINARY=$(find "$NODE_DIR" -name "node-*-linux-amd64" -type f -executable -printf "%f\n" | sort -V | tail -n 1)

if [ -z "$NODE_BINARY" ]; then
    echo "Error: Could not find node binary in $NODE_DIR"
    exit 1
fi

echo "Using node binary: $NODE_BINARY"

# Initialize parent_pid with the script's PID
parent_pid=$$

# Function to start processes
start_processes() {
    # If starting from core 0, launch the master process
    if [ $START_CORE -eq 0 ]; then
        echo "Starting master node..."
        $NODE_DIR/$NODE_BINARY &
        parent_pid=$!
        sleep 5  # Wait for the master process to initialize
        # Adjust the range to exclude the master process
        START_CORE=1
    else
        echo "Starting worker node..."
    fi

    echo "Parent process ID: $parent_pid"

    # Start worker processes
    for core in $(seq $START_CORE $END_CORE); do
        echo "Deploying: $core data worker with params: --core=$core --parent-process=$parent_pid"
        $NODE_DIR/$NODE_BINARY --core=$core --parent-process=$parent_pid &
        sleep 2  # Add a small delay between starting processes
    done
}

# Function to kill all node processes
kill_all_nodes() {
    pkill -f "$NODE_BINARY"
    sleep 5  # Wait for processes to terminate
}

# Trap to handle script termination
trap 'kill_all_nodes; exit' EXIT INT TERM

# Kill any existing node processes
kill_all_nodes

# Start processes
start_processes

# Keep the script running
while true; do
    sleep 3600
done
