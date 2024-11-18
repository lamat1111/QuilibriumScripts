#!/bin/bash

# Description:
# This script analyzes proof creation and submission frame ages to determine
# likelihood of proofs landing successfully.
# It analyzes both "creating data shard ring proof" and "submitting data proof" events.
#
# Usage:  ~/scripts/qnode_proof_monitor.sh [minutes]
# Example:  ~/scripts/qnode_proof_monitor.sh 600    # analyzes last 10 hours

# Script version
SCRIPT_VERSION="3.2"

# Default time window in minutes (1 hour by default)
DEFAULT_TIME_WINDOW=180

# Get time window from command line argument or use default
TIME_WINDOW=${1:-$DEFAULT_TIME_WINDOW}

# Convert minutes to hours for journalctl (rounded up)
HOURS_AGO=$(( (TIME_WINDOW + 59) / 60 ))

# Service Configuration
if systemctl list-units --full -all | grep -Fq "qmaster.service"; then
    SERVICE_NAME=qmaster
else
    SERVICE_NAME=ceremonyclient
fi

# Frame Age Thresholds (in seconds)
# Creation stage thresholds
CREATION_OPTIMAL_MIN=1
CREATION_OPTIMAL_MAX=17
CREATION_WARNING_MAX=50  

# Submission stage thresholds
SUBMISSION_OPTIMAL_MIN=1
SUBMISSION_OPTIMAL_MAX=28
SUBMISSION_WARNING_MAX=70  

# Colors and formatting
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'
GRAY='\033[38;5;240m'
SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Function to check for newer script version
check_for_updates() {
    LATEST_VERSION=$(wget -qO- "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_proof_monitor.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/scripts/qnode_proof_monitor.sh "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_proof_monitor.sh"
        chmod +x ~/scripts/qnode_proof_monitor.sh
        sleep 1
    fi
}

# Function to calculate average and standard deviation
calculate_stats() {
    local file=$1
    
    # Calculate average
    local avg=$(awk '{ sum += $1; n++ } END { if (n > 0) printf "%.2f", sum / n }' "$file")
    
    # Calculate standard deviation
    # Using formula: sqrt(Σ(x - μ)²/(n-1))
    local stddev=$(awk -v avg="$avg" '
        BEGIN { sum = 0; n = 0 }
        { 
            diff = $1 - avg
            sum += diff * diff
            n++
        }
        END { 
            if (n > 1) 
                printf "%.2f", sqrt(sum / (n-1))
            else 
                printf "0"
        }' "$file")
    
    # Get min and max
    local min=$(awk 'NR == 1 { min = $1 } $1 < min { min = $1 } END { printf "%.2f", min }' "$file")
    local max=$(awk 'NR == 1 { max = $1 } $1 > max { max = $1 } END { printf "%.2f", max }' "$file")
    
    echo "$avg $stddev $min $max"
}
# Check for updates and update if available
check_for_updates

# Helper function for section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${RESET}"
    echo -e "${BLUE}$SEPARATOR${RESET}"
}

# Calculate percentage of proofs in each category
calculate_percentages() {
    local file=$1
    local stage=$2
    local total=$(wc -l < "$file")
    
    if [ "$stage" = "creation" ]; then
        # Creation stage ranges
        local optimal=$(awk -v min="$CREATION_OPTIMAL_MIN" -v max="$CREATION_OPTIMAL_MAX" \
            '$1 >= min && $1 <= max {count++} END {print count+0}' "$file")
        local warning=$(awk -v max="$CREATION_OPTIMAL_MAX" -v warn="$CREATION_WARNING_MAX" \
            '$1 > max && $1 <= warn {count++} END {print count+0}' "$file")
        local critical=$(awk -v warn="$CREATION_WARNING_MAX" \
            '$1 > warn {count++} END {print count+0}' "$file")
    else
        # Submission stage ranges - comparison operators fixed
        local optimal=$(awk -v min="$SUBMISSION_OPTIMAL_MIN" -v max="$SUBMISSION_OPTIMAL_MAX" \
            '$1 >= min && $1 <= max {count++} END {print count+0}' "$file")
        local warning=$(awk -v max="$SUBMISSION_OPTIMAL_MAX" -v warn="$SUBMISSION_WARNING_MAX" \
            '$1 > max && $1 <= warn {count++} END {print count+0}' "$file")
        local critical=$(awk -v warn="$SUBMISSION_WARNING_MAX" \
            '$1 > warn {count++} END {print count+0}' "$file")
    fi
    
    # Verify total adds up
    if [ "$((optimal + warning + critical))" -ne "$total" ]; then
        echo "Warning: Category counts don't add up to total" >&2
    fi
    
    echo "$optimal $warning $critical"
}

# Function to get latest ring and workers numbers
get_latest_stats() {
    local latest_log=$(journalctl -u $SERVICE_NAME.service --since "$HOURS_AGO hours ago" | grep -F "submitting data proof" | tail -n 1)
    local ring=$(echo "$latest_log" | grep -o '"ring":[0-9]\+' | cut -d':' -f2)
    local workers=$(echo "$latest_log" | grep -o '"active_workers":[0-9]\+' | cut -d':' -f2)
    
    # If empty, mark as unknown
    if [ -z "$workers" ]; then
        workers="unknown"
    fi
    
    echo "$ring $workers"
}

# Temporary files
TEMP_CREATE=$(mktemp)
TEMP_SUBMIT=$(mktemp)

print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last ${BOLD}$TIME_WINDOW${RESET} minutes (${BOLD}$HOURS_AGO${RESET} hours)..."

# Extract frame_age values with proper precision
journalctl -u $SERVICE_NAME.service --since "$HOURS_AGO hours ago" | grep -F "creating data shard ring proof" | \
    sed -E 's/.*"frame_age":([0-9]+\.[0-9]+).*/\1/' > "$TEMP_CREATE"

journalctl -u $SERVICE_NAME.service --since "$HOURS_AGO hours ago" | grep -F "submitting data proof" | \
    sed -E 's/.*"frame_age":([0-9]+\.[0-9]+).*/\1/' > "$TEMP_SUBMIT"

# Calculate statistics if we have data
if [ -s "$TEMP_CREATE" ] && [ -s "$TEMP_SUBMIT" ]; then
    CREATE_STATS=($(calculate_percentages "$TEMP_CREATE" "creation"))
    SUBMIT_STATS=($(calculate_percentages "$TEMP_SUBMIT" "submission"))
    NODE_STATS=($(get_latest_stats))
    
    # Calculate average and standard deviation
    CREATE_AGE_STATS=($(calculate_stats "$TEMP_CREATE"))
    SUBMIT_AGE_STATS=($(calculate_stats "$TEMP_SUBMIT"))
    
    TOTAL_CREATES=$(wc -l < "$TEMP_CREATE")
    TOTAL_SUBMITS=$(wc -l < "$TEMP_SUBMIT")
    
    # Display results
    print_header "🔄 CREATION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_CREATES${RESET} creation events:\n"
    
    CREATE_OPTIMAL_PCT=$(( CREATE_STATS[0] * 100 / TOTAL_CREATES ))
    CREATE_WARNING_PCT=$(( CREATE_STATS[1] * 100 / TOTAL_CREATES ))
    CREATE_CRITICAL_PCT=$(( CREATE_STATS[2] * 100 / TOTAL_CREATES ))
    
    # Only color if percentage > 50%
    OPTIMAL_COLOR=""
    WARNING_COLOR=""
    CRITICAL_COLOR=""
    
    (( CREATE_OPTIMAL_PCT > 50 )) && OPTIMAL_COLOR=$GREEN
    (( CREATE_WARNING_PCT > 50 )) && WARNING_COLOR=$YELLOW
    (( CREATE_CRITICAL_PCT > 50 )) && CRITICAL_COLOR=$RED

    echo -e "${OPTIMAL_COLOR}${BOLD}$CREATE_OPTIMAL_PCT%${RESET} ${OPTIMAL_COLOR}Good!${RESET} (${CREATION_OPTIMAL_MIN}-${CREATION_OPTIMAL_MAX}s) - ${BOLD}${CREATE_STATS[0]}${RESET} proofs"
    echo -e "${WARNING_COLOR}${BOLD}$CREATE_WARNING_PCT%${RESET} ${WARNING_COLOR}Meh...${RESET} (${CREATION_OPTIMAL_MAX}-${CREATION_WARNING_MAX}s) - ${BOLD}${CREATE_STATS[1]}${RESET} proofs"
    echo -e "${CRITICAL_COLOR}${BOLD}$CREATE_CRITICAL_PCT%${RESET} ${CRITICAL_COLOR}Ouch!${RESET} (>${CREATION_WARNING_MAX}s) - ${BOLD}${CREATE_STATS[2]}${RESET} proofs"
    
    echo -e "${GRAY}Average Frame Age: ${BOLD}${CREATE_AGE_STATS[0]}s${RESET}"
    echo -e "${GRAY}Standard Deviation: ${BOLD}${CREATE_AGE_STATS[1]}s${RESET} ${GRAY}(lower is better)${RESET}"
    echo -e "${GRAY}Lowest Frame Age: ${BOLD}${CREATE_AGE_STATS[2]}s${RESET}"
    echo -e "${GRAY}Highest Frame Age: ${BOLD}${CREATE_AGE_STATS[3]}s${RESET}${RESET}"
    
    print_header "📤 SUBMISSION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_SUBMITS${RESET} submission events:\n"
    
    SUBMIT_OPTIMAL_PCT=$(( SUBMIT_STATS[0] * 100 / TOTAL_SUBMITS ))
    SUBMIT_WARNING_PCT=$(( SUBMIT_STATS[1] * 100 / TOTAL_SUBMITS ))
    SUBMIT_CRITICAL_PCT=$(( SUBMIT_STATS[2] * 100 / TOTAL_SUBMITS ))
    
    # Reset colors and set only if percentage > 50%
    OPTIMAL_COLOR=""
    WARNING_COLOR=""
    CRITICAL_COLOR=""
    
    (( SUBMIT_OPTIMAL_PCT > 50 )) && OPTIMAL_COLOR=$GREEN
    (( SUBMIT_WARNING_PCT > 50 )) && WARNING_COLOR=$YELLOW
    (( SUBMIT_CRITICAL_PCT > 50 )) && CRITICAL_COLOR=$RED

    echo -e "${OPTIMAL_COLOR}${BOLD}$SUBMIT_OPTIMAL_PCT%${RESET} ${OPTIMAL_COLOR}Good!${RESET} (${SUBMISSION_OPTIMAL_MIN}-${SUBMISSION_OPTIMAL_MAX}s) - ${BOLD}${SUBMIT_STATS[0]}${RESET} proofs"
    echo -e "${WARNING_COLOR}${BOLD}$SUBMIT_WARNING_PCT%${RESET} ${WARNING_COLOR}Meh...${RESET} (${SUBMISSION_OPTIMAL_MAX}-${SUBMISSION_WARNING_MAX}s) - ${BOLD}${SUBMIT_STATS[1]}${RESET} proofs"
    echo -e "${CRITICAL_COLOR}${BOLD}$SUBMIT_CRITICAL_PCT%${RESET} ${CRITICAL_COLOR}Ouch!${RESET} (>${SUBMISSION_WARNING_MAX}s) - ${BOLD}${SUBMIT_STATS[2]}${RESET} proofs"
    
    echo -e "\n${GRAY}Average Frame Age: ${BOLD}${SUBMIT_AGE_STATS[0]}s${RESET}"
    echo -e "${GRAY}Standard Deviation: ${BOLD}${SUBMIT_AGE_STATS[1]}%${RESET} ${GRAY}(lower is better)${RESET}"
    echo -e "${GRAY}Lowest Frame Age: ${BOLD}${SUBMIT_AGE_STATS[2]}s${RESET}"
    echo -e "${GRAY}Highest Frame Age: ${BOLD}${SUBMIT_AGE_STATS[3]}s${RESET}${RESET}"
    
    # Overall health assessment
    print_header "📋 OVERALL HEALTH ASSESSMENT"
    CREATE_OPTIMAL_PCT=$(( CREATE_STATS[0] * 100 / TOTAL_CREATES ))
    CREATE_WARNING_PCT=$(( CREATE_STATS[1] * 100 / TOTAL_CREATES ))
    CREATE_CRITICAL_PCT=$(( CREATE_STATS[2] * 100 / TOTAL_CREATES ))
    
    SUBMIT_OPTIMAL_PCT=$(( SUBMIT_STATS[0] * 100 / TOTAL_SUBMITS ))
    SUBMIT_WARNING_PCT=$(( SUBMIT_STATS[1] * 100 / TOTAL_SUBMITS ))
    SUBMIT_CRITICAL_PCT=$(( SUBMIT_STATS[2] * 100 / TOTAL_SUBMITS ))
    
    # Only CRITICAL if majority of proofs are in critical range for both stages
    if (( CREATE_CRITICAL_PCT > 50 && SUBMIT_CRITICAL_PCT > 50 )); then
        echo -e "Status: ${RED}${BOLD}CRITICAL${RESET} 🔴"
        echo -e "Majority of proofs are outside optimal ranges. System needs attention."
    # WARNING if either stage has more warnings+critical than optimal
    elif (( CREATE_OPTIMAL_PCT < 50 || SUBMIT_OPTIMAL_PCT < 50 )); then
        echo -e "Status: ${YELLOW}${BOLD}SUBOPTIMAL${RESET} 🟡"
        echo -e "Some proofs are outside optimal ranges but may still land successfully."
    else
        echo -e "Status: ${GREEN}${BOLD}HEALTHY${RESET} 🟢"
        echo -e "Most proofs are within acceptable ranges and likely to land successfully."
    fi
    
    echo -e "\nRing: ${BOLD}${NODE_STATS[0]}${RESET}"
    echo -e "Workers: ${BOLD}${NODE_STATS[1]}${RESET}"
    
else
    echo -e "\n${RED}${BOLD}No proofs found in the last $TIME_WINDOW minutes${RESET}"
fi

# Cleanup
rm -f "$TEMP_CREATE" "$TEMP_SUBMIT"

# Print footer with optimal ranges and usage
print_header "ℹ️ USAGE INFO"
echo -e "Optimal ranges:"
echo -e "Creation stage:  ${BOLD}$CREATION_OPTIMAL_MIN-$CREATION_OPTIMAL_MAX${RESET} seconds"
echo -e "Submission stage: ${BOLD}$SUBMISSION_OPTIMAL_MIN-$SUBMISSION_OPTIMAL_MAX${RESET} seconds"
echo -e "\nTo analyze a different time window:"
echo -e "$HOME/scripts/qnode_proof_monitor.sh [minutes]"
echo -e "Example: $HOME/scripts/qnode_proof_monitor.sh 600  # analyzes last 10 hours"
echo -e "\nv $SCRIPT_VERSION"
echo