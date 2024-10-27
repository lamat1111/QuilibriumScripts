#!/bin/bash

# Configurable time interval (default 10 minutes)
TIME_INTERVAL=${1:-10}

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function for animated loading message
animate_loading() {
    local message="$1"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    
    while true; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -en "\r${CYAN}${chars:$i:1}${NC} ${message}"
            sleep $delay
        done
    done
}

# Start animation in background
animate_loading "Checking your increments..." &
ANIM_PID=$!

# Trap to ensure we kill the animation on script exit
trap "kill $ANIM_PID 2>/dev/null" EXIT

# Calculate how many minutes of logs we need (time interval + 5 minutes buffer)
MINUTES_TO_FETCH=$((TIME_INTERVAL + 5))

# Get recent log entries more efficiently
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "$MINUTES_TO_FETCH minutes ago" | grep increment)

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
    echo -e "${YELLOW}WARNING: No proof submissions found in the last $TIME_INTERVAL minutes!${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Increment Analysis for the last $TIME_INTERVAL minutes ===${NC}"
echo "___________________________________________________________"

echo "$entries_window" | awk -v current_time="$(date +%s)" \
    -v green="${GREEN}" -v yellow="${YELLOW}" -v blue="${BLUE}" -v cyan="${CYAN}" -v nc="${NC}" '
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
    
    last_decrement_gap = int(current_time - previous_time);
    last_decrement_minutes = last_decrement_gap / 60;
    avg_time_per_batch = (count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - increment;
    
    printf "%sStarting increment:%s %d\n", blue, nc, first_increment;
    printf "%sCurrent increment:%s %d\n", blue, nc, increment;
    printf "%sTotal decrease:%s %d\n", green, nc, total_decrease;
    printf "%sLast Decrease:%s %.1f minutes ago\n", yellow, nc, last_decrement_minutes;
    printf "%sAvg Time per Batch (200 increments):%s %.2f Seconds\n", cyan, nc, avg_time_per_batch;
    printf "\n%s=== Completion Estimates ===%s\n", blue, nc;
    printf "Time to complete your %s%d%s remaining Increments: %s%.2f days%s\n", 
        yellow, increment, nc, green, (increment * (avg_time_per_batch/200)) / 86400, nc;
    printf "___________________________________________________________\n";
}
'