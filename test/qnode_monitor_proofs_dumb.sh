#!/bin/bash

echo "Checking your log (this will take a minute)..."

# Minutes in the past to check
TIME_CHECK="120"

get_proof_entries() {
    journalctl -u ceremonyclient.service --no-hostname --since "$TIME_CHECK minutes ago" -r | \
    grep "proof batch.*increment" | \
    tac
}

# Get the proof entries
log_entries=$(get_proof_entries)

# Check if we have any entries
if [ -z "$log_entries" ]; then
    echo "WARNING: No proof submissions found in the last $TIME_CHECK minutes!"
    echo "This is also true if you have already minted all your rewards."
    exit 1
fi

# Process entries with simplified awk
echo
echo "=== Proof submissions in last $TIME_CHECK minutes ==="
echo "___________________________________________________________"

echo "$log_entries" | awk -v current_time="$(date +%s)" '
BEGIN {
    total_time = 0;
    total_decrement = 0;
    gap_count = 0;
    first_entry = 1;
    total_entries = 0;
}
{
    total_entries++;
    
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
        print "No increment changes detected";
        exit 1;
    }
    
    if (previous_increment == 0) {
        print "";
        print "Congratulations!";
        print "You have already minted all your rewards!";
        print "";
        print "___________________________________________________________";
        exit 0;
    }
    
    last_decrement_gap = current_time - previous_time;
    minutes_since_last = last_decrement_gap / 60;
    
    span_minutes = (previous_time - first_time) / 60;
    avg_interval = gap_count > 0 ? span_minutes / gap_count : 0;
    
    avg_time_per_batch = (gap_count > 0 && total_decrement > 0) ? (total_time / (total_decrement/200)) : 0;
    total_decrease = first_increment - previous_increment;
    
    print "=== Current State ===";
    print "Starting increment:", first_increment;
    print "Current increment:", previous_increment;
    print "Total decrease:", total_decrease;
    print "";
    
    print "=== Time Analysis ===";
    
    if (minutes_since_last > 30) {
        print "WARNING: No recent proofs!";
        print "Last batch submitted:", sprintf("%.2f", minutes_since_last), "minutes ago";
    } else {
        print "Last batch submitted:", sprintf("%.2f", minutes_since_last), "minutes ago";
    }
    print "";
    
    print "When active, batches were submitted every", sprintf("%.2f", avg_interval), "minutes";
    print "The analyzed", total_entries, "batches were submitted within", sprintf("%.2f", span_minutes), "minutes";
    print "";
    
    if (minutes_since_last > (avg_interval * 10)) {
        print "Note: Proof submission delay detected";
        print "Last proof is", sprintf("%.1f", minutes_since_last/avg_interval), "x older than the average interval";
        print "This could be normal and the node could recover on its own";
        print "If needed, wait at least 1 hour between restarts";
        print "";
    }
    
    print "=== Processing Speed ===";
    if (avg_time_per_batch > 0) {
        print "Avg Time per Batch (200 increments):", sprintf("%.2f", avg_time_per_batch), "Seconds";
        print "";
        
        print "=== Completion Estimates ===";
        days_to_complete = (previous_increment * (avg_time_per_batch/200)) / 86400;
        print "Time to complete your", previous_increment, "remaining Increments:", sprintf("%.2f", days_to_complete), "days";
        print "";
    } else {
        print "WARNING: Could not calculate average batch time";
        print "";
    }
    
    print "___________________________________________________________";
}
'