#!/bin/bash

# Get all recent log entries with increments
log_entries=$(journalctl -u ceremonyclient.service --no-hostname | grep increment | tail -n 100)

# Get the most recent timestamp
latest_ts=$(echo "$log_entries" | tail -n 1 | grep -o '"ts":[0-9]*\.[0-9]*' | cut -d: -f2)

# Calculate timestamp from 10 minutes ago
ten_min_ago=$(echo "$latest_ts - 600" | bc)

# Filter entries within last 10 minutes and get increments
entries_10min=$(echo "$log_entries" | awk -v cutoff="$ten_min_ago" '
    {
        # Extract timestamp
        match($0, /"ts":([0-9]+\.[0-9]+)/, ts)
        # Extract increment
        match($0, /"increment":([0-9]+)/, inc)
        
        if (ts[1] >= cutoff) {
            print ts[1] " " inc[1]
        }
    }
')

# Check if we have any entries
if [ -z "$entries_10min" ]; then
    echo "WARNING: No proof submissions found in the last 10 minutes!"
    echo "Latest timestamp: $latest_ts"
    echo "Checking since: $ten_min_ago"
    exit 1
fi

# Get first and last entries
first_entry=$(echo "$entries_10min" | head -n 1)
last_entry=$(echo "$entries_10min" | tail -n 1)

# Parse values
first_ts=$(echo "$first_entry" | cut -d' ' -f1)
first_increment=$(echo "$first_entry" | cut -d' ' -f2)
last_ts=$(echo "$last_entry" | cut -d' ' -f1)
last_increment=$(echo "$last_entry" | cut -d' ' -f2)

# Count entries
entry_count=$(echo "$entries_10min" | wc -l)

# Calculate batches (each batch decreases by 200)
if [ -n "$first_increment" ] && [ -n "$last_increment" ]; then
    difference=$((first_increment - last_increment))
    complete_batches=$((difference / 200))
    time_diff=$(echo "$last_ts - $first_ts" | bc)
    
    echo "=== Proof Submission Analysis ==="
    echo "Time window: $(date -d @${first_ts%.*}) to $(date -d @${last_ts%.*})"
    echo "Duration: ${time_diff%.*} seconds"
    echo ""
    echo "Starting increment: $first_increment"
    echo "Current increment: $last_increment"
    echo "Total decrease: $difference"
    echo ""
    echo "Complete batches: $complete_batches"
    
    if [ $complete_batches -gt 0 ]; then
        # Calculate batch rate
        batch_rate=$(echo "scale=2; $complete_batches / ($time_diff / 60)" | bc)
        
        echo ""
        echo "=== Rate Analysis ==="
        echo "Batches per minute: $batch_rate"
        
        if [ $difference -gt 0 ]; then
            echo ""
            echo "Status: HEALTHY - Proof batches are being submitted"
            exit 0
        else
            echo ""
            echo "Status: WARNING - No decrease in increment value"
            exit 1
        fi
    else
        echo ""
        echo "Status: WARNING - No complete batches in the time window"
        exit 1
    fi
else
    echo "ERROR: Could not parse increment values"
    exit 1
fi