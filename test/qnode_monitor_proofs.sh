#!/bin/bash

# Color definitions - only keeping warning/error colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Fetch 60 minutes of logs
MINUTES_TO_FETCH=60

echo "Checking your increments..."

# Get current timestamp before fetching logs
current_timestamp=$(date +%s.%N)

# Get recent log entries more efficiently
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "$MINUTES_TO_FETCH minutes ago" | grep increment)

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found in the last $MINUTES_TO_FETCH minutes!${NC}"
    echo "${YELLOW}Can also happen if you have already minted all your rewards.${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Increment Analysis (checking last 60 minutes) ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$current_timestamp" \
    -v minutes_to_fetch="$MINUTES_TO_FETCH" \
    -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" -v bold="${BOLD}" '
BEGIN {
    count = 0;
}
{
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
    timestamp = ts[1];
    increment = inc[1];
    
    # Store first and last seen timestamps and increments
    if (NR == 1) {
        first_timestamp = timestamp;
        first_increment = increment;
    }
    last_timestamp = timestamp;
    last_increment = increment;
}
END {
    if (NR == 0) {
        printf "%sNo increment changes detected in the time window%s\n", yellow, nc;
        exit 1;
    }
    
    # Check if increment has reached 0
    if (last_increment == 0) {
        printf "\n🎉 Congratulations! 🎉\n";
        printf "%sYou have already minted all your rewards!%s\n", bold, nc;
        printf "___________________________________________________________\n";
        exit 0;
    }
    
    # Calculate total time window in minutes
    window_size = minutes_to_fetch;  # Using full window size
    
    # Calculate total decrease in the time window
    total_decrease = first_increment - last_increment;
    
    # Calculate number of complete batches (each batch is 200)
    num_batches = total_decrease / 200;
    
    # Calculate average time per batch based on window size
    if (num_batches > 0) {
        # Convert window from minutes to seconds for consistency
        avg_seconds_per_batch = (window_size * 60) / num_batches;
    } else {
        avg_seconds_per_batch = 0;
    }
    
    # Calculate minutes since last proof with higher precision
    time_since_last = current_time - last_timestamp;
    if (time_since_last < 0) time_since_last = 0;
    minutes_since_last = time_since_last / 60;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", last_increment;
    printf "Total decrease: %d\n", total_decrease;
    printf "Complete batches in last %d minutes: %.1f\n", window_size, num_batches;
    
    # Use yellow for warnings about timing
    if (minutes_since_last > 10) {
        printf "%sLast Decrease: %.1f minutes ago%s\n", yellow, minutes_since_last, nc;
    } else {
        printf "Last Decrease: %.1f minutes ago\n", minutes_since_last;
    }
    
    if (avg_seconds_per_batch > 0) {
        printf "Avg Time per Batch (200 increments): %.2f Seconds\n", avg_seconds_per_batch;
        printf "\n=== Completion Estimates ===\n";
        printf "Time to complete your %d remaining Increments: %.2f days\n", 
            last_increment, (last_increment * (avg_seconds_per_batch/200)) / 86400;
    } else {
        printf "%sWARNING: No complete batches in the time window to calculate average%s\n", yellow, nc;
    }
    printf "___________________________________________________________\n";
}
'