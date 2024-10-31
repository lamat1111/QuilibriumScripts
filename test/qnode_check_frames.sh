#!/bin/bash

#####################
# Configuration
#####################
# Time window in seconds (3600 = 1 hour)
MAX_TIME_WITHOUT_FRAMES=3600
QUIL_SERVICE_NAME="ceremonyclient"

#####################
# Colors
#####################
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#####################
# Logs
#####################

# Log configuration
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/frame_number_check.log"
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

# Get the most recent frame number and its timestamp
recent_data=$(journalctl -u $QUIL_SERVICE_NAME --no-hostname --output=json -r |
    jq -r 'select(.frame_number != null) | [.ts, .frame_number] | @csv' |
    head -n 1)

if [ -z "$recent_data" ]; then
    echo -e "${YELLOW}WARNING: No recent frame data found. Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

# Parse the recent data
recent_ts=$(echo $recent_data | cut -d',' -f1 | tr -d '"')
recent_frame=$(echo $recent_data | cut -d',' -f2 | tr -d '"')

# Get current timestamp
current_ts=$(date +%s)

# Calculate time since last frame
time_diff=$(echo "$current_ts - $recent_ts" | bc)

echo "Most recent frame number: $recent_frame"
echo "Time since last frame: $time_diff seconds ($(echo "$time_diff/60" | bc) minutes)"
echo "Maximum allowed time without frames: $MAX_TIME_WITHOUT_FRAMES seconds ($(echo "$MAX_TIME_WITHOUT_FRAMES/60" | bc) minutes)"

# Check if we haven't received a frame in the configured time window
if [ "$time_diff" -gt "$MAX_TIME_WITHOUT_FRAMES" ]; then
    echo -e "${YELLOW}WARNING: No new frames in the last $(echo "$MAX_TIME_WITHOUT_FRAMES/60" | bc) minutes. Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

echo "Node is operating normally - last frame was $time_diff seconds ago"

#####################
# Logs - clean
#####################

# Rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"