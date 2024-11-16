#!/bin/bash

SERVICE_NAME=ceremonyclient
#SERVICE_NAME=qmaster

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

# Get logs and extract timestamps
print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last ${BOLD}$MINUTES_AGO${RESET} minutes..."

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
    
    # Divide the time window into 10-minute intervals for rate calculation
    INTERVAL=600  # 10 minutes in seconds
    
    # Generate rate data points for regression
    current_ts=$FIRST_TS
    while (( $(echo "$current_ts < $LAST_TS" | bc -l) )); do
        next_ts=$(echo "$current_ts + $INTERVAL" | bc -l)
        count=$(awk -v start="$current_ts" -v end="$next_ts" '$1 >= start && $1 < end' "$TEMP_FILE" | wc -l)
        # Output: time_offset_in_hours rate_per_hour
        time_offset=$(echo "($current_ts - $FIRST_TS) / 3600" | bc -l)
        rate=$(echo "$count * (3600 / $INTERVAL)" | bc -l)
        echo "$time_offset $rate" >> "$RATE_DATA"
        current_ts=$next_ts
    done
    
    # Calculate linear regression using awk
    REGRESSION=$(awk '
    BEGIN {
        sum_x = 0; sum_y = 0
        sum_xy = 0; sum_xx = 0
        sum_yy = 0; n = 0
    }
    {
        x = $1; y = $2
        sum_x += x; sum_y += y
        sum_xy += x * y
        sum_xx += x * x
        sum_yy += y * y
        n++
    }
    END {
        if (n < 2) {
            printf "0 0 0"
            exit
        }
        mean_x = sum_x / n
        mean_y = sum_y / n
        
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
        intercept = mean_y - slope * mean_x
        
        ss_tot = 0; ss_res = 0
        for (i = 1; i <= n; i++) {
            x = $1; y = $2
            y_pred = slope * x + intercept
            ss_tot += (y - mean_y) * (y - mean_y)
            ss_res += (y - y_pred) * (y - y_pred)
        }
        r_squared = (ss_tot > 0) ? (1 - ss_res / ss_tot) : 0
        
        printf "%.6f %.6f %.6f", slope, intercept, r_squared
    }' "$RATE_DATA")
    
    # Extract regression values
    SLOPE=$(echo "$REGRESSION" | cut -d' ' -f1)
    INTERCEPT=$(echo "$REGRESSION" | cut -d' ' -f2)
    R_SQUARED=$(echo "$REGRESSION" | cut -d' ' -f3)
    
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
        CONFIDENCE="High confidence"
    elif (( $(echo "$R_SQUARED > 0.3" | bc -l) )); then
        CONFIDENCE_COLOR=$YELLOW
        CONFIDENCE="Medium confidence"
    else
        CONFIDENCE_COLOR=$RED
        CONFIDENCE="Low confidence"
    fi
    
    # Output sections
    print_header "📈 OVERALL STATISTICS"
    echo -e "Time Window:    ${BOLD}$(printf "%.1f" $HOURS)${RESET} hours (${BOLD}$(printf "%.1f" $MINUTES)${RESET} minutes)"
    echo -e "Total Proofs:   ${BOLD}$TOTAL_PROOFS${RESET}"
    
    print_header "🚀 PROOF SUBMISSION RATES"
    echo -e "Hourly Rate:    $(format_value $RATE_PER_HOUR "proofs/hr")"
    echo -e "Minute Rate:    $(format_value $RATE_PER_MINUTE "proofs/min")"
    
    print_header "📉 TREND ANALYSIS"
    echo -e "Rate Change:    $(format_value $SLOPE "proofs/hr²")"
    echo -e "Change Rate:    ${TREND_COLOR}$(printf "%+.2f" $PCT_CHANGE_PER_HOUR)%%${RESET} per hour"
    echo -e "Trend:         ${TREND_COLOR}$TREND_ARROW ${BOLD}$TREND${RESET}"
    echo -e "Confidence:    ${CONFIDENCE_COLOR}$CONFIDENCE${RESET} (R² = $(printf "%.4f" $R_SQUARED))"
    
    print_header "📋 SUMMARY"
    echo -e "${BOLD}${TREND_COLOR}$TREND_ARROW${RESET} Proof submission rate is ${TREND_COLOR}${BOLD}$TREND${RESET} at"
    echo -e "   ${BOLD}$(printf "%+.2f" $PCT_CHANGE_PER_HOUR)%%${RESET} per hour with ${CONFIDENCE_COLOR}${BOLD}$CONFIDENCE${RESET}"
else
    echo -e "\n${RED}${BOLD}No proofs found in the last $MINUTES_AGO minutes${RESET}"
fi

# Cleanup
rm "$TEMP_FILE" "$RATE_DATA"