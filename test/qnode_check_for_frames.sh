#!/bin/bash

#####################
# Colors
#####################
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#####################
# Logs - add
#####################

# Log configuration
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/qnode_check_for_frames.log"
LOG_ENTRIES=1000

# Create log directory if needed
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}WARNING: Log directory does not exist. Creating $LOG_DIR...${NC}"
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "ERROR: Failed to create log directory $LOG_DIR"
        exit 1
    fi
fi

# Set up logging with timestamps
exec 1> >(while read line; do echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1

#####################
# Script
#####################

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
            echo -e "${YELLOW}WARNING: Unknown option: $1${NC}"
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
    echo -e "${YELLOW}WARNING:Restarting the node...${NC}"
    echo ""
    service $QUIL_SERVICE_NAME restart
}

# Get the initial timestamp
last_timestamp=$(get_latest_frame_received_timestamp | awk '{print int($1)}')

if [ -z "$last_timestamp" ]; then
    echo -e "${YELLOW}WARNING: No frames received timestamp found at all in latest logs. Restarting the node...${NC}"
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
    echo -e "${YELLOW}WARNING: No new leading frame received in the last $DIFF seconds. Restarting the node...${NC}"
    restart_application
else
    echo "New leading frame received within the last $DIFF seconds. No action needed."
fi

#####################
# Logs - clean
#####################

# At the end of script, rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"