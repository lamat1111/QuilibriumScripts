#!/bin/bash

# Description:
# This script analyzes proof submission rates from either the qmaster or ceremonyclient service.
# It calculates submission rates, trends, and provides statistical analysis over a specified time window.
# The script automatically checks for qmaster service first, falling back to ceremonyclient if not found.
#
# Usage: ./script.sh [minutes]
# Default time window is 180 minutes (3 hours)

# Check if qmaster service exists
if systemctl list-units --full -all | grep -Fq "qmaster.service"; then
    SERVICE_NAME=qmaster
else
    SERVICE_NAME=ceremonyclient
fi

# Colors and formatting
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'
SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Helper function for section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${RESET}"
    echo -e "${BLUE}$SEPARATOR${RESET}"
}

# Helper function for values with units
format_value() {
    local value=$1
    local unit=$2
    printf "${BOLD}%9.2f${RESET} ${CYAN}%-10s${RESET}" "$value" "$unit"
}

# Time window in minutes (default: 180 minutes = 3 hours)
MINUTES_AGO=${1:-180}

# Convert minutes to hours for journalctl
HOURS_AGO=$((MINUTES_AGO / 60))

# Temporary files
TEMP_FILE=$(mktemp)
RATE_DATA=$(mktemp)

print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last ${BOLD}$MINUTES_AGO${RESET} minutes..."

# Get the last complete log entry and extract ring and workers
LAST_LOG=$(journalctl -u $SERVICE_NAME.service --since "${HOURS_AGO} hours ago" | grep -F "msg\":\"submitting data proof" | tail -n 1)
RING_NUMBER=$(echo "$LAST_LOG" | grep -o '"ring":[0-9]*' | cut -d':' -f2)
ACTIVE_WORKERS=$(echo "$LAST_LOG" | grep -o '"active_workers":[0-9]*' | cut -d':' -f2)

# Extract timestamps
journalctl -u $SERVICE_NAME.service --since "${HOURS_AGO} hours ago" | \
    grep -F "msg\":\"submitting data proof" | \
    sed -E 's/.*"ts":([0-9]+\.[0-9]+).*/\1/' > "$TEMP_FILE"

# Calculate statistics if we have data
if [ -s "$TEMP_FILE" ]; then
    # Get first and last timestamp
    FIRST_TS=$(head -n 1 "$TEMP_FILE")
    LAST_TS=$(tail -n 1 "$TEMP_FILE")
    
    # Count total proofs
    TOTAL_PROOFS=$(wc -l < "$TEMP_FILE")
    
    # Calculate time difference in hours and minutes
    TIME_DIFF=$(echo "$LAST_TS - $FIRST_TS" | bc)
    HOURS=$(echo "$TIME_DIFF / 3600" | bc -l)
    MINUTES=$(echo "$TIME_DIFF / 60" | bc -l)
    
    # Calculate overall rates
    RATE_PER_HOUR=$(echo "$TOTAL_PROOFS / $HOURS" | bc -l)
    RATE_PER_MINUTE=$(echo "$TOTAL_PROOFS / $MINUTES" | bc -l)
    
    # Divide time window into 10-minute intervals for regression
    INTERVAL=600  # 10 minutes in seconds
    current_ts=$FIRST_TS
    while (( $(echo "$current_ts < $LAST_TS" | bc -l) )); do
        next_ts=$(echo "$current_ts + $INTERVAL" | bc -l)
        count=$(awk -v start="$current_ts" -v end="$next_ts" '$1 >= start && $1 < end' "$TEMP_FILE" | wc -l)
        time_offset=$(echo "($current_ts - $FIRST_TS) / 3600" | bc -l)
        rate=$(echo "$count * (3600 / $INTERVAL)" | bc -l)
        echo "$time_offset $rate" >> "$RATE_DATA"
        current_ts=$next_ts
    done
    
    # Calculate linear regression
    REGRESSION=$(awk '
    BEGIN {
        sum_x = 0; sum_y = 0
        sum_xy = 0; sum_xx = 0
        n = 0
    }
    {
        x = $1; y = $2
        sum_x += x; sum_y += y
        sum_xy += x * y
        sum_xx += x * x
        n++
    }
    END {
        if (n < 2) {
            printf "0 0 0"
            exit
        }
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
        r_squared = (sum_xy - sum_x * sum_y / n)^2 / \
                   ((sum_xx - sum_x^2/n) * (sum_yy - sum_y^2/n))
        printf "%.6f %.6f", slope, r_squared
    }' "$RATE_DATA")
    
    SLOPE=$(echo "$REGRESSION" | cut -d' ' -f1)
    R_SQUARED=$(echo "$REGRESSION" | cut -d' ' -f2)
    
    # Calculate percentage change per hour
    PCT_CHANGE_PER_HOUR=$(echo "($SLOPE / $RATE_PER_HOUR) * 100" | bc -l)
    
    # Determine trend and confidence
    if (( $(echo "$SLOPE > 0" | bc -l) )); then
        TREND_COLOR=$GREEN
        TREND_ARROW="↑"
        TREND="Increasing"
    elif (( $(echo "$SLOPE < 0" | bc -l) )); then
        TREND_COLOR=$RED
        TREND_ARROW="↓"
        TREND="Decreasing"
    else
        TREND_COLOR=$YELLOW
        TREND_ARROW="→"
        TREND="Stable"
    fi
    
    if (( $(echo "$R_SQUARED > 0.7" | bc -l) )); then
        CONFIDENCE_COLOR=$GREEN
        CONFIDENCE="High"
    elif (( $(echo "$R_SQUARED > 0.3" | bc -l) )); then
        CONFIDENCE_COLOR=$YELLOW
        CONFIDENCE="Medium"
    else
        CONFIDENCE_COLOR=$RED
        CONFIDENCE="Low"
    fi

    echo "This script is still in BETA, feel free to post"
    echo "your suggestions for improvements in the Q1 Telegram channel"
    echo
    
    print_header "📈 OVERALL STATISTICS"
    echo -e "Time Window:    ${BOLD}$(printf "%.1f" $HOURS)${RESET} hours (${BOLD}$(printf "%.1f" $MINUTES)${RESET} minutes)"
    echo -e "Total Proofs:   ${BOLD}$TOTAL_PROOFS${RESET}"
    echo -e "Ring Number:    ${BOLD}$RING_NUMBER${RESET}"
    echo -e "Active Workers: ${BOLD}$ACTIVE_WORKERS${RESET}"
    
    print_header "🚀 PROOF SUBMISSION RATES"
    echo -e "Hourly Rate:    $(format_value $RATE_PER_HOUR "proofs/hr")"
    echo -e "Minute Rate:    $(format_value $RATE_PER_MINUTE "proofs/min")"
    
    print_header "📉 TREND ANALYSIS"
    echo -e "Rate Change:    $(format_value $SLOPE "proofs/hr²")"
    echo -e "Change Rate:    ${TREND_COLOR}$(printf "%+.2f" $PCT_CHANGE_PER_HOUR)%%${RESET} per hour"
    echo -e "Trend:         ${TREND_COLOR}$TREND_ARROW ${BOLD}$TREND${RESET}"
    echo -e "Confidence:    ${CONFIDENCE_COLOR}$CONFIDENCE${RESET} confidence (R² = $(printf "%.4f" $R_SQUARED))"
    
    print_header "📋 SUMMARY"
    echo -e "${BOLD}${TREND_COLOR}$TREND_ARROW${RESET} Proof submission rate is ${TREND_COLOR}${BOLD}$TREND${RESET} at"
    echo -e "   ${BOLD}$(printf "%+.2f" $PCT_CHANGE_PER_HOUR)%%${RESET} per hour with ${CONFIDENCE_COLOR}${BOLD}$CONFIDENCE${RESET} confidence"
else
    echo -e "\n${RED}${BOLD}No proofs found in the last $MINUTES_AGO minutes${RESET}"
fi

# Cleanup
rm -f "$TEMP_FILE" "$RATE_DATA"

# Print footer with usage information
echo -e "\n${BOLD}${BLUE}ℹ️ USAGE INFO${RESET}"
echo -e "${BLUE}$SEPARATOR${RESET}"
echo -e "To run for a different time window you can run:"
echo -e "$HOME/scripts/qnode_proof_rate.sh x, where x is a number of minutes,"
echo -e "e.g. $HOME/scripts/qnode_proof_rate.sh 600"