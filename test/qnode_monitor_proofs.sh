#!/bin/bash

# Color definitions - only keeping warning/error colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'



# Start animation in background
echo "Checking your increments..."

# Fetch 60 minutes of logs
MINUTES_TO_FETCH=60

# Get current timestamp before fetching logs
current_timestamp=$(date +%s.%N)

# Get recent log entries more efficiently
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "$MINUTES_TO_FETCH minutes ago" | grep increment)

# Kill animation and clear line
kill $ANIM_PID 2>/dev/null
echo -en "\r\033[K"

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found in the last $MINUTES_TO_FETCH minutes!${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Increment Analysis (checking last 60 minutes) ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$current_timestamp" \
    -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" -v bold="${BOLD}" '
BEGIN {
    total_time=0;
    total_decrement=0;
    count=0;
}
{
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
    if (NR == 1) {
        first_increment = inc[1];
    }
    
    entry_time = ts[1];
    increment = inc[1];
    
    if (previous_time && previous_increment) {
        time_gap = entry_time - previous_time;
        decrement = previous_increment - increment;
        
        if (decrement > 0) {
            total_time += time_gap;
            total_decrement += decrement;
            count++;
        }
    }
    
    previous_time = entry_time;
    previous_increment = increment;
}
END {
    if (count == 0) {
        printf "%sNo increment changes detected in the time window%s\n", yellow, nc;
        exit 1;
    }
    
    # Check if increment has reached 0
    if (increment == 0) {
        printf "\n🎉 Congratulations! 🎉\n";
        printf "%sYou have already minted all your rewards!%s\n", bold, nc;
        printf "___________________________________________________________\n";
        exit 0;
    }
    
    # Calculate minutes since last proof with higher precision
    time_since_last = current_time - previous_time;
    if (time_since_last < 0) time_since_last = 0;  # Safeguard against negative values
    minutes_since_last = time_since_last / 60;
    
    avg_time_per_batch = (count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - increment;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", increment;
    printf "Total decrease: %d\n", total_decrease;
    
    # Use yellow for warnings about timing
    if (minutes_since_last > 10) {
        printf "%sLast Decrease: %.1f minutes ago%s\n", yellow, minutes_since_last, nc;
    } else {
        printf "Last Decrease: %.1f minutes ago\n", minutes_since_last;
    }
    
    printf "Avg Time per Batch (200 increments): %.2f Seconds\n", avg_time_per_batch;
    printf "\n=== Completion Estimates ===\n";
    printf "Time to complete your %d remaining Increments: %.2f days\n", 
        increment, (increment * (avg_time_per_batch/200)) / 86400;
    printf "___________________________________________________________\n";
}
'