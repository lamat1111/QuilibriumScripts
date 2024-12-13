#!/bin/bash

SCRIPT_VERSION=1.0

# Colors and formatting
BOLD='\033[1m'
BLUE='\033[94m'
YELLOW='\033[33m'
RED='\033[31m'
NC='\033[0m' # No Color

# Icons (Unicode)
WARNING="⚠️"
PROCESSING="⚙️"

# Set default minutes to 60 if no argument provided
if [ $# -eq 0 ]; then
    minutes=60
else
    # Validate input is a positive number
    if ! [[ $1 =~ ^[0-9]+$ ]]; then
        echo -e "${RED}${WARNING} Error: Please provide a positive number of minutes${NC}"
        exit 1
    fi
    minutes=$1
fi

# Show processing message
echo -e "\n${BLUE}${PROCESSING}   Processing... Please wait${NC}\n"

# Get current timestamp
current_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Process the input data
process_data() {
    while IFS= read -r line; do
        amount=$(echo "$line" | awk '{print $1}')
        timestamp=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z')
        
        current_seconds=$(date -d "$current_timestamp" +%s)
        coin_seconds=$(date -d "$timestamp" +%s)
        time_diff=$(( (current_seconds - coin_seconds) / 60 ))
        
        if [ $time_diff -le $minutes ]; then
            echo "$timestamp $amount $time_diff"
        fi
    done | sort -k1,1
}

# Format timestamp to human readable
format_timestamp() {
    local timestamp=$1
    date -d "$timestamp" "+%Y-%m-%d %H:%M:%S UTC"
}

# Calculate statistics from the processed data
calculate_stats() {
    local total=0
    local count=0
    local first_timestamp=""
    local last_timestamp=""
    
    while IFS=' ' read -r timestamp amount mins; do
        if [ -z "$first_timestamp" ]; then
            first_timestamp=$timestamp
        fi
        last_timestamp=$timestamp
        total=$(echo "$total + $amount" | bc)
        ((count++))
    done

    if [ $count -eq 0 ]; then
        echo -e "${RED}${INFO} No data found for the last $minutes minutes${NC}"
        exit 0
    fi

    # Calculate average per coin
    average=$(echo "scale=8; $total / $count" | bc)
    
    # Calculate time span of available data
    start_seconds=$(date -d "$first_timestamp" +%s)
    end_seconds=$(date -d "$last_timestamp" +%s)
    span_minutes=$(( (end_seconds - start_seconds) / 60 ))
    
    # Calculate rewards per minute for projections
    rewards_per_minute=$(echo "scale=8; $total / $span_minutes" | bc)
    
    # Project hourly and daily rates
    hourly_rewards=$(echo "scale=8; $rewards_per_minute * 60" | bc)
    daily_rewards=$(echo "scale=8; $rewards_per_minute * 1440" | bc)
    
    # Format timestamps
    start_time=$(format_timestamp "$first_timestamp")
    end_time=$(format_timestamp "$last_timestamp")
    
    echo -e "${BOLD}Analysis Results:${NC}"
    echo -e "------------------------------------------------------------"
    echo -e "Time range: $start_time to $end_time"
    echo -e "Time span analized: $span_minutes minutes"
    echo ""
    echo -e "${BOLD}Current Data:${NC}"
    echo -e "  Number of coins analyzed: ${BOLD}$count${NC}"
    echo -e "  Average QUIL per coin: ${BOLD}$average${NC}"
    echo -e "  Total QUIL rewards: ${BOLD}$total${NC}"
    echo ""
    echo -e "${BOLD}Projections:${NC}"
    echo -e "  Hourly QUIL: ${BOLD}$hourly_rewards${NC}"
    echo -e "  Daily QUIL: ${BOLD}$daily_rewards${NC}"
    
    if [ $span_minutes -lt 60 ]; then
        echo ""
        echo -e "${BLUE}Hourly projections are based on less than one hour of data${NC}"
    fi
    if [ $span_minutes -lt 1440 ]; then
        echo -e "${BLUE}Daily projections are based on less than 24 hours of data${NC}"
    fi
    echo "------------------------------------------------------------"
    echo
    echo "To analyze a different time span add the number of minutes to the command, e.g.:"
    echo "$HOME/scripts/qnode_rewards_monitor.sh 180"
    echo
    echo "$SCRIPT_VERSION"
}

# Main execution
qclient_output=$(qclient token coins metadata --config /root/ceremonyclient/node/.config --public-rpc)
echo "$qclient_output" | process_data | calculate_stats