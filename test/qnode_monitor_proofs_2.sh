#!/bin/bash

# Function for animated loading message
animate_loading() {
    local message="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    
    while true; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -en "\r${message} ${chars:$i:1}"
            sleep $delay
        done
    done
}

# Start animation in background
animate_loading "Checking your increments..." &
ANIM_PID=$!

# Trap to ensure we kill the animation on script exit
trap "kill $ANIM_PID 2>/dev/null" EXIT

# Get log entries with increments
log_entries=$(journalctl -u ceremonyclient.service --no-hostname | grep increment | tail -n 2000)

# Kill animation and clear line
kill $ANIM_PID 2>/dev/null
echo -en "\r\033[K"

# Get the most recent timestamp
latest_ts=$(echo "$log_entries" | tail -n 1 | grep -o '"ts":[0-9]*\.[0-9]*' | cut -d: -f2)
current_time=$(date +%s)

# Process entries with awk
echo "=== Increment Analysis ==="
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$current_time" '
BEGIN {
    total_time=0;
    total_decrement=0;
    count=0;
}
{
    # Extract timestamp and increment
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
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
    last_decrement_gap = (current_time - previous_time);
    avg_time_per_decrement = (count > 0 && total_decrement > 0) ? total_time / total_decrement : 0;
    
    # Calculate rates
    decrements_per_minute = 60 / avg_time_per_decrement;
    decrements_per_hour = decrements_per_minute * 60;
    decrements_per_day = decrements_per_hour * 24;
    
    printf "\033[1;34m=== Current Rates ===\033[0m\n"
    printf "Increments per minute: %.2f\n", decrements_per_minute;
    printf "Increments per hour: %.2f\n", decrements_per_hour;
    printf "Increments per day: %.2f\n\n", decrements_per_day;
    
    printf "\033[1;34m=== Time Statistics ===\033[0m\n"
    printf "\033[0;32mLast Decrease: %d Seconds ago\033[0m\n", last_decrement_gap;
    printf "\033[1;33mAvg Time per Increment: %.6f seconds\033[0m\n\n", avg_time_per_decrement;
    
    printf "\033[1;34m=== Completion Estimates ===\033[0m\n"
    printf "\033[0;36mTime to complete your %d remaining Increments: %.2f days\033[0m\n", previous_increment, (previous_increment * avg_time_per_decrement) / 86400;
    
    # Milestone estimates
    milestones = "3000000 2500000 2000000 1500000 1000000 500000 250000";
    split(milestones, milestone_arr, " ");
    for (i in milestone_arr) {
        remaining = milestone_arr[i];
        days = (remaining * avg_time_per_decrement) / 86400;
        printf "Time to complete from %d Increments: %.2f days\n", remaining, days;
    }
    
    printf "___________________________________________________________\n"
}
'