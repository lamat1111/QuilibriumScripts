#!/bin/bash

# Color definitions - only keeping warning/error colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo "Checking your increments..."

# Get current Unix timestamp (with nanoseconds for precision)
current_timestamp=$(date +%s)
# Calculate timestamp from 60 minutes ago (60 * 60 = 3600 seconds)
since_timestamp=$((current_timestamp - 3600))

# Get recent log entries using grep with timestamp filter
log_entries=$(journalctl -u ceremonyclient.service --no-hostname | grep increment | awk -v since=$since_timestamp '
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts) {
        if (ts[1] >= since) {
            print $0
        }
    }
')

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found in the last 60 minutes!${NC}"
    echo -e "${YELLOW}Can also happen if you have already minted all your rewards.${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Increment Analysis (checking last 60 minutes) ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$current_timestamp" \
    -v since_time="$since_timestamp" \
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
    
    # Calculate actual time window observed in the logs (in seconds)
    actual_window = last_timestamp - first_timestamp;
    
    # Calculate total decrease in the time window
    total_decrease = first_increment - last_increment;
    
    # Calculate number of complete batches (each batch is 200)
    num_batches = total_decrease / 200;
    
    # Calculate average time per batch based on actual window
    if (num_batches > 0) {
        avg_seconds_per_batch = actual_window / num_batches;
    } else {
        avg_seconds_per_batch = 0;
    }
    
    # Calculate minutes since last proof
    time_since_last = current_time - last_timestamp;
    if (time_since_last < 0) time_since_last = 0;
    minutes_since_last = time_since_last / 60;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", last_increment;
    printf "Total decrease: %d\n", total_decrease;
    printf "Complete batches in last %.1f minutes: %.1f\n", actual_window/60, num_batches;
    
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