#!/bin/bash

# Color definitions
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo "Checking your increments..."

# Function to get last N proof submissions
get_proof_entries() {
    local required_proofs=30
    local found_proofs=0
    local buffer=""
    
    # Read journalctl output in reverse, line by line, until we have enough proofs
    journalctl -u ceremonyclient.service --no-hostname -r | while IFS= read -r line; do
        if echo "$line" | grep -q "proof batch.*increment"; then
            buffer="${buffer}${line}\n"
            ((found_proofs++))
            
            if [ $found_proofs -eq $required_proofs ]; then
                # Found enough proofs, output them in correct order (reverse again)
                echo -e "$buffer" | tac
                exit 0
            fi
        fi
    done
}

# Get the proof entries
log_entries=$(get_proof_entries)

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found!${NC}"
    exit 1
fi

# Process entries with awk
echo -e "${BOLD}=== Increment Analysis (last 30 submissions) ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$(date +%s)" \
    -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" -v bold="${BOLD}" '
BEGIN {
    total_time=0;
    total_decrement=0;
    count=0;
    first_time = 0;
}
{
    # Extract timestamp and increment from JSON format
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
    entry_time = ts[1];
    increment = inc[1];
    
    if (NR == 1) {
        first_increment = increment;
        first_time = entry_time;
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
    
    # Calculate time span of the 30 proofs
    total_span = previous_time - first_time;
    avg_time_between_proofs = total_span / (NR - 1);  # NR-1 gives intervals between N proofs
    
    # Calculate averages for batches
    avg_time_per_batch = (count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - previous_increment;
    
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", previous_increment;
    printf "Total decrease: %d\n", total_decrease;
    
    # Time statistics
    if (minutes_since_last > 10) {
        printf "%sLast proof submitted: %.1f minutes ago%s\n", yellow, minutes_since_last, nc;
    } else {
        printf "Last proof submitted: %.1f minutes ago\n", minutes_since_last;
    }
    
    printf "Average time between proofs: %.2f seconds (%.2f minutes)\n", 
        avg_time_between_proofs, avg_time_between_proofs/60;
    printf "Time span of last %d proofs: %.2f minutes\n", NR, total_span/60;
    
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