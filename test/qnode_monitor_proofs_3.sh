#!/bin/bash

# Configurable time interval (default 10 minutes)
TIME_INTERVAL=${1:-10}

# Function for animated loading message
animate_loading() {
    local message="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    
    while true; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -en "\r${chars:$i:1} ${message}"
            sleep $delay
        done
    done
}

# Start animation in background
animate_loading "Checking your increments..." &
ANIM_PID=$!

# Trap to ensure we kill the animation on script exit
trap "kill $ANIM_PID 2>/dev/null" EXIT

# Get all recent log entries with increments
log_entries=$(journalctl -u ceremonyclient.service --no-hostname | grep increment | tail -n 2000)

# Get the most recent timestamp
latest_ts=$(echo "$log_entries" | tail -n 1 | grep -o '"ts":[0-9]*\.[0-9]*' | cut -d: -f2)

# Calculate timestamp from X minutes ago
minutes_ago=$(echo "$latest_ts - (60 * $TIME_INTERVAL)" | bc)

# Filter entries within time window
entries_window=$(echo "$log_entries" | awk -v cutoff="$minutes_ago" '
    {
        match($0, /"ts":([0-9]*\.[0-9]*)/, ts)
        if (ts[1] >= cutoff) {
            print $0
        }
    }
')

# Kill animation and clear line
kill $ANIM_PID 2>/dev/null
echo -en "\r\033[K"

# Check if we have any entries
if [ -z "$entries_window" ]; then
    echo "WARNING: No proof submissions found in the last $TIME_INTERVAL minutes!"
    exit 1
fi

# Process entries with awk
echo "=== Increment Analysis for the last $TIME_INTERVAL minutes ==="
echo "___________________________________________________________"

echo "$entries_window" | awk -v current_time="$(date +%s)" '
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
        printf "No increment changes detected in the time window\n";
        exit 1;
    }
    
    last_decrement_gap = int(current_time - previous_time);
    avg_time_per_decrement = (count > 0 && total_decrement > 0) ? total_time / total_decrement : 0;
    total_decrease = first_increment - increment;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", increment;
    printf "Total decrease: %d\n", total_decrease;
    printf "Last Decrease: %d Seconds ago\n", last_decrement_gap;
    printf "Avg Time per Increment: %f Seconds\n", avg_time_per_decrement;
    printf "\n=== Completion Estimates ===\n";
    printf "Time to complete your %d remaining Increments: %.2f days\n", increment, (increment * avg_time_per_decrement) / 86400;
    printf "___________________________________________________________\n";
}
'