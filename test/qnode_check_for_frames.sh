#!/bin/bash

# Parse command line arguments
DIFF=600  # Default value for diff

if [ -z "$QUIL_SERVICE_NAME" ]; then
    QUIL_SERVICE_NAME="ceremonyclient"
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --diff)
            DIFF="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Using diff: $DIFF seconds"

# Function to get the latest timestamp
get_latest_frame_received_timestamp() {
    journalctl -u $QUIL_SERVICE_NAME --no-hostname -g "received new leading frame" --output=cat -r -n 1 | jq -r '.ts'
}

get_latest_timestamp() {
    journalctl -u $QUIL_SERVICE_NAME --no-hostname --output=cat -r -n 1 | jq -r '.ts'
}

restart_application() {
    echo "Restarting the node..."
    service ceremonyclient restart
}

# Get the initial timestamp
last_timestamp=$(get_latest_frame_received_timestamp | awk '{print int($1)}')

if [ -z "$last_timestamp" ]; then
    echo "No frames recieved timestamp found at all in latest logs. Restarting the node..."
    restart_application
    exit 1
fi

# Get the current timestamp
current_timestamp=$(get_latest_timestamp | awk '{print int($1)}')

echo "Last timestamp: $last_timestamp"
echo "Current timestamp: $current_timestamp"

# Calculate the time difference
time_diff=$(echo "$current_timestamp - $last_timestamp" | bc)

echo "Time difference: $time_diff seconds"

# If the time difference is more than $DIFF, restart the node
if [ $time_diff -gt $DIFF ]; then
    echo "No new leading frame received in the last $DIFF seconds. Restarting the node..."
    restart_application
else
    echo "New leading frame received within the last $DIFF seconds. No action needed."
fi
