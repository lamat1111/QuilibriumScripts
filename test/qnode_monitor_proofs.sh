#!/bin/bash

# Color definitions - only keeping warning/error colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo
echo "Checking your increments..."

# Get log entries with better filtering
og_entries=$(journalctl -u ceremonyclient.service --no-hostname -n 20000 | grep "proof batch.*increment" | tail -n 30)

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found in the last 20.000 log entries!${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Last 30 proof submissions ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$(date +%s)" \
    -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" -v bold="${BOLD}" '
BEGIN {
    total_time=0;
    total_decrement=0;
    count=0;
}
{
    # Extract timestamp and increment from JSON format
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
    entry_time = ts[1];  # Using the ts field directly
    increment = inc[1];
    
    if (NR == 1) {
        first_increment = increment;
    }
    
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
        printf "%sNo increment changes detected%s\n", yellow, nc;
        exit 1;
    }
    
    # Check if increment has reached 0
    if (previous_increment == 0) {
        printf "\n🎉 Congratulations! 🎉\n";
        printf "%sYou have already minted all your rewards!%s\n", bold, nc;
        printf "___________________________________________________________\n";
        exit 0;
    }
    
    # Calculate time since last proof
    last_decrement_gap = current_time - previous_time;
    minutes_since_last = last_decrement_gap / 60;
    
    # Calculate averages
    avg_time_per_batch = (count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - previous_increment;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", previous_increment;
    printf "Total decrease: %d\n", total_decrease;
    
    # Use yellow for warnings about timing
    if (minutes_since_last > 10) {
        printf "%sLast Decrease: %.1f minutes ago%s\n", yellow, minutes_since_last, nc;
    } else {
        printf "Last Decrease: %.1f minutes ago\n", minutes_since_last;
    }
    
    if (avg_time_per_batch > 0) {
        printf "Avg Time per Batch (200 increments): %.2f Seconds\n", avg_time_per_batch;
        printf "\n=== Completion Estimates ===\n";
        days_to_complete = (previous_increment * (avg_time_per_batch/200)) / 86400;
        printf "Time to complete your %d remaining Increments: %.2f days\n", 
            previous_increment, days_to_complete;
    } else {
        printf "%sWARNING: Could not calculate average batch time%s\n", yellow, nc;
    }
    printf "___________________________________________________________\n";
}
'