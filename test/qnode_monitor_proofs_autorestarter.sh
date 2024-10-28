#!/bin/bash

# Color definitions
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo "Checking your log (this will take a minute)..."

#minutes in the past to check
TIME_CHECK="120" 

# Function to get last N proof submissions - can be very slow if there are no proofs, it scans the log until it finds them
# get_proof_entries() {
#     local required_proofs=30
#     local found_proofs=0
#     local buffer=""
    
#     # Read journalctl output in reverse, line by line, until we have enough proofs
#     journalctl -u ceremonyclient.service --no-hostname -r | while IFS= read -r line; do
#         if echo "$line" | grep -q "proof batch.*increment"; then
#             buffer="$line\n$buffer"
#             ((found_proofs++))
            
#             if [ $found_proofs -eq $required_proofs ]; then
#                 echo -e "$buffer"
#                 exit 0
#             fi
#         fi
#     done
# }

get_proof_entries() {
    journalctl -u ceremonyclient.service --no-hostname --since "$TIME_CHECK minutes ago" -r | \
    grep "proof batch.*increment" | \
    tac
}

# Get the proof entries
log_entries=$(get_proof_entries)

# Check if we have any entries

# Function to count proof entries
count_proofs=$(echo "$log_entries" | wc -l)

if [ -z "$log_entries" ]; then
    echo -e "${YELLOW}WARNING: No proof submissions found in the last $TIME_CHECK minutes!${NC}"
    echo "This is also true if you have already minted all your rewards."
    exit 1
fi


# Process entries with awk
echo
echo -e "${BOLD}=== Proof submissions in last $TIME_CHECK minutes ===${NC}"
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$(date +%s)" \
    -v yellow="${YELLOW}" -v red="${RED}" -v nc="${NC}" -v bold="${BOLD}" \
    -v time_check="$TIME_CHECK" '
BEGIN {
    total_time=0;
    total_decrement=0;
    gap_count=0;
    first_entry = 1;
    total_entries = 0;
}
{
    # Count each entry
    total_entries++;
    
    # Extract timestamp and increment from JSON format
    match($0, /"ts":([0-9]+\.[0-9]+)/, ts);
    match($0, /"increment":([0-9]+)/, inc);
    
    entry_time = ts[1];
    increment = inc[1];
    
    if (first_entry) {
        first_time = entry_time;
        first_increment = increment;
        first_entry = 0;
    }
    
    if (previous_time) {
        time_gap = entry_time - previous_time;
        decrement = previous_increment - increment;
        if (decrement > 0) {
            total_time += time_gap;
            total_decrement += decrement;
            gap_count++;
        }
    }
    
    previous_time = entry_time;
    previous_increment = increment;
}
END {
    if (gap_count == 0) {
        printf "%sNo increment changes detected%s\n", yellow, nc;
        exit 1;
    }
    
    # Check if increment has reached 0
    if (previous_increment == 0) {
        printf "\n🎉 Congratulations! 🎉\n";
        printf "%sYou have already minted all your rewards!%s\n\n", bold, nc;
        printf "___________________________________________________________\n";
        exit 0;
    }
    
    # Calculate time since last proof
    last_decrement_gap = current_time - previous_time;
    minutes_since_last = last_decrement_gap / 60;
    
    # Calculate time span of the proofs (only valid intervals)
    span_minutes = (previous_time - first_time) / 60;
    avg_interval = gap_count > 0 ? span_minutes / gap_count : 0;
    
    # Calculate batch statistics
    avg_time_per_batch = (gap_count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - previous_increment;
    
    # Increment Information
    printf "=== Current State ===\n";
    printf "Starting increment: %d\n", first_increment;
    printf "Current increment: %d\n", previous_increment;
    printf "Total decrease: %d\n\n", total_decrease;
    
    # Time Analysis
    printf "=== Time Analysis ===\n";
    
    # Time statistics with improved clarity
    if (minutes_since_last > 30) {
        printf "%sWARNING: No recent proofs!\n", yellow;
        printf "Last batch submitted: %.2f minutes ago%s\n\n", minutes_since_last, nc;
    } else {
        printf "Last batch submitted: %.2f minutes ago\n\n", minutes_since_last;
    }
    
    printf "When active, batches were submitted every %.2f minutes\n", avg_interval;
    printf "The analyzed %d batches were submitted within %.2f minutes\n\n", total_entries, span_minutes;
    
    # Add warning if last proof is much older than the average interval
    if (minutes_since_last > (avg_interval * 10)) {
        printf "%sNote: Proof submission delay detected%s\n", yellow, nc;
        printf "Last proof is %.1fx older than the average interval\n", minutes_since_last/avg_interval;
        printf "This could be normal and the node could recover on its own\n";
        printf "If needed, wait at least 1 hour between restarts\n\n";
    }
        
    # Processing Speed
    printf "=== Processing Speed ===\n";
    if (avg_time_per_batch > 0) {
        printf "Avg Time per Batch (200 increments): %.2f Seconds\n\n", avg_time_per_batch;
        
        # Completion Estimates
        printf "=== Completion Estimates ===\n";
        days_to_complete = (previous_increment * (avg_time_per_batch/200)) / 86400;
        printf "Time to complete your %d remaining Increments: %.2f days\n\n", 
            previous_increment, days_to_complete;
    } else {
        printf "%sWARNING: Could not calculate average batch time%s\n\n", yellow, nc;
    }
    
    printf "___________________________________________________________\n";
}
'
echo