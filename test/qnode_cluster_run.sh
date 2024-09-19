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

# Automatically determine if this is a master or slave node
if [ $START_CORE -eq 0 ]; then
    NODE_TYPE="master"
else
    NODE_TYPE="slave"
fi

echo "Detected node type: $NODE_TYPE"

# Automatically detect the node binary
NODE_DIR="/root/ceremonyclient/node"
NODE_BINARY=$(find "$NODE_DIR" -name "node-*-linux-amd64" -type f -executable -printf "%f\n" | sort -V | tail -n 1)

if [ -z "$NODE_BINARY" ]; then
    echo "Error: Could not find node binary in $NODE_DIR"
    exit 1
fi

echo "Using node binary: $NODE_BINARY"

# Initialize parent_pid
parent_pid=$$

# Function to start processes
start_processes() {
    # Kill any existing node processes
    pkill -f "$NODE_BINARY"
    sleep 5  # Wait for processes to terminate

    if [ "$NODE_TYPE" = "master" ]; then
        echo "Starting master node..."
        $NODE_DIR/$NODE_BINARY &
        parent_pid=$!
        sleep 5  # Wait for the master process to initialize
        # Adjust the range to exclude the master process
        START_CORE=1
    else
        echo "Running in slave mode, using script PID as parent."
    fi

    echo "Parent process ID: $parent_pid"

    # Start worker processes
    for core in $(seq $START_CORE $END_CORE); do
        echo "Deploying: $core data worker with params: --core=$core --parent-process=$parent_pid"
        $NODE_DIR/$NODE_BINARY --core=$core --parent-process=$parent_pid &
        sleep 2  # Add a small delay between starting processes
    done
}

# Function to check if the parent process is running
is_parent_process_running() {
    if [ -n "$parent_pid" ]; then
        if kill -0 $parent_pid 2>/dev/null; then
            return 0  # Process is running
        else
            return 1  # Process is not running
        fi
    else
        return 1  # No parent process ID set
    fi
}

# Trap to handle script termination
trap 'pkill -f "$NODE_BINARY"; exit' EXIT INT TERM

# Start processes initially
start_processes

# Main loop
if [ "$NODE_TYPE" = "master" ]; then
    echo "Running in master mode, monitoring parent process..."
    while true; do
        if ! is_parent_process_running; then
            echo "Parent process crashed or stopped. Restarting all processes..."
            start_processes
        fi
        sleep 60  # Sleep for 1 minute before next check
    done
else
    echo "Running in slave mode, no monitoring needed."
    # Keep the script running
    while true; do
        sleep 3600
    done
fi
