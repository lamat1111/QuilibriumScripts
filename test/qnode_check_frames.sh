#!/bin/bash

#####################
# Configuration
#####################
MAX_TIME_WITHOUT_FRAMES=3600  # 1 hour
QUIL_SERVICE_NAME="ceremonyclient"

#####################
# Colors
#####################
YELLOW='\033[1;33m'
NC='\033[0m'

#####################
# Logs
#####################
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/frame_number_check.log"

# Create log directory if needed
[ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR" 2>/dev/null

# Set up logging with timestamps
exec 1> >(while read line; do echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1

#####################
# Script
#####################

# Calculate timestamps for sampling points
now=$(date '+%Y-%m-%d %H:%M:%S')
min15_ago=$(date -d '15 minutes ago' '+%Y-%m-%d %H:%M:%S')
min30_ago=$(date -d '30 minutes ago' '+%Y-%m-%d %H:%M:%S')
min45_ago=$(date -d '45 minutes ago' '+%Y-%m-%d %H:%M:%S')
hour_ago=$(date -d '60 minutes ago' '+%Y-%m-%d %H:%M:%S')

# Function to get frame number at a specific time
get_frame_at_time() {
    local target_time=$1
    local window_size="1min"  # Look in 1-minute window to find a frame
    
    journalctl -u $QUIL_SERVICE_NAME --no-hostname --output=json \
        --since "$target_time" --until "$(date -d "$target_time + $window_size" '+%Y-%m-%d %H:%M:%S')" |
        jq -r 'select(.frame_number != null and .msg == "evaluating next frame") | [.ts, .frame_number] | @csv' |
        head -n 1
}

# Get frame numbers at sampling points
current_data=$(get_frame_at_time "$now")
min15_data=$(get_frame_at_time "$min15_ago")
min30_data=$(get_frame_at_time "$min30_ago")
min45_data=$(get_frame_at_time "$min45_ago")

# Extract latest frame and timestamp
if [ -z "$current_data" ]; then
    echo -e "${YELLOW}WARNING: No current frame data found. Service might be stuck. Last log entries:${NC}"
    journalctl -u $QUIL_SERVICE_NAME --no-hostname -n 5
    echo -e "${YELLOW}Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

latest_ts=$(echo "$current_data" | cut -d',' -f1 | tr -d '"')
latest_frame=$(echo "$current_data" | cut -d',' -f2 | tr -d '"')

# Convert timestamp to seconds
current_ts=$(date +%s)
time_diff=$(( current_ts - ${latest_ts%.*} ))

# Extract all frame numbers for comparison
frame15=$(echo "$min15_data" | cut -d',' -f2 | tr -d '"')
frame30=$(echo "$min30_data" | cut -d',' -f2 | tr -d '"')
frame45=$(echo "$min45_data" | cut -d',' -f2 | tr -d '"')

echo "Frame number analysis:"
echo "Current frame: $latest_frame"
echo "15 min ago  : ${frame15:-N/A}"
echo "30 min ago  : ${frame30:-N/A}"
echo "45 min ago  : ${frame45:-N/A}"
echo "Time since last frame: $time_diff seconds ($(( time_diff/60 )) minutes)"

# Check frame progression across samples
frame_increased=false
prev_frame=0

# Function to compare frames
is_greater() {
    local frame=$1
    if [ ! -z "$frame" ] && [ "$frame" -gt "$prev_frame" ]; then
        return 0
    fi
    return 1
}

# Check progression through all valid samples
if [ ! -z "$frame45" ]; then prev_frame=$frame45; fi
if [ ! -z "$frame30" ] && is_greater "$frame30"; then frame_increased=true; prev_frame=$frame30; fi
if [ ! -z "$frame15" ] && is_greater "$frame15"; then frame_increased=true; prev_frame=$frame15; fi
if [ ! -z "$latest_frame" ] && is_greater "$latest_frame"; then frame_increased=true; fi

if [ "$frame_increased" = false ]; then
    echo -e "${YELLOW}WARNING: Frame numbers not increasing. Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

# Check if we haven't received a frame in the configured time window
if [ "$time_diff" -gt "$MAX_TIME_WITHOUT_FRAMES" ]; then
    echo -e "${YELLOW}WARNING: No new frames in the last $(( MAX_TIME_WITHOUT_FRAMES/60 )) minutes. Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

echo "Node is operating normally - last frame was $time_diff seconds ago"

# Keep only the last 1000 lines of the log file
tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"