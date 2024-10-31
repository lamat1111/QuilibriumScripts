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

# Calculate timestamps for sampling points (now, 20min ago, 40min ago, and 60min ago)
now=$(date '+%Y-%m-%d %H:%M:%S')
min20_ago=$(date -d '20 minutes ago' '+%Y-%m-%d %H:%M:%S')
min40_ago=$(date -d '40 minutes ago' '+%Y-%m-%d %H:%M:%S')
hour_ago=$(date -d '60 minutes ago' '+%Y-%m-%d %H:%M:%S')

# Function to get frame number at a specific time
get_frame_at_time() {
    local target_time=$1
    local window_size="1min"  # Look in 1-minute window to find a frame
    
    journalctl -u $QUIL_SERVICE_NAME --no-hostname --output=json \
        --since "$target_time" --until "$(date -d "$target_time + $window_size" '+%Y-%m-%d %H:%M:%S')" |
        grep '"frame_number":' |
        head -n 1 |
        jq -r 'select(.frame_number != null) | [.REALTIME_TIMESTAMP, .frame_number] | @csv'
}

# Get frame numbers at sampling points
current_data=$(get_frame_at_time "$now")
min20_data=$(get_frame_at_time "$min20_ago")
min40_data=$(get_frame_at_time "$min40_ago")
hour_data=$(get_frame_at_time "$hour_ago")

# Extract latest frame and timestamp
if [ -z "$current_data" ]; then
    echo -e "${YELLOW}WARNING: No current frame data found. Restarting the node...${NC}"
    service $QUIL_SERVICE_NAME restart
    exit 1
fi

latest_ts=$(echo "$current_data" | cut -d',' -f1 | tr -d '"')
latest_frame=$(echo "$current_data" | cut -d',' -f2 | tr -d '"')

# Convert timestamp to seconds
current_ts=$(date +%s)
latest_ts_seconds=$(echo "scale=0; $latest_ts/1000000" | bc)
time_diff=$(( current_ts - latest_ts_seconds ))

# Extract all frame numbers for comparison
frame20=$(echo "$min20_data" | cut -d',' -f2 | tr -d '"')
frame40=$(echo "$min40_data" | cut -d',' -f2 | tr -d '"')
frame60=$(echo "$hour_data" | cut -d',' -f2 | tr -d '"')

echo "Frame number analysis:"
echo "Current frame: $latest_frame"
echo "20 min ago  : ${frame20:-N/A}"
echo "40 min ago  : ${frame40:-N/A}"
echo "60 min ago  : ${frame60:-N/A}"
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
if [ ! -z "$frame60" ]; then prev_frame=$frame60; fi
if [ ! -z "$frame40" ] && is_greater "$frame40"; then frame_increased=true; prev_frame=$frame40; fi
if [ ! -z "$frame20" ] && is_greater "$frame20"; then frame_increased=true; prev_frame=$frame20; fi
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