#!/bin/bash

# Description:
# This script analyzes proof creation and submission frame ages to determine
# likelihood of proofs landing successfully.
# It analyzes both "creating data shard ring proof" and "submitting data proof" events.
#
# Usage:  ~/scripts/qnode_proof_monitor.sh [minutes]
# Example:  ~/scripts/qnode_proof_monitor.sh 600    # analyzes last 10 hours

# Script version
SCRIPT_VERSION="1.8"

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
CREATION_OPTIMAL_MIN=13
CREATION_OPTIMAL_MAX=17
CREATION_WARNING_MAX=50  

# Submission stage thresholds
SUBMISSION_OPTIMAL_MIN=24
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
        local optimal=$(awk -v min="$CREATION_OPTIMAL_MIN" -v max="$CREATION_OPTIMAL_MAX" \
            '$2 >= min && $2 <= max {count++} END {print count}' "$file")
        local warning=$(awk -v max="$CREATION_OPTIMAL_MAX" -v warn="$CREATION_WARNING_MAX" \
            '$2 > max && $2 <= warn {count++} END {print count}' "$file")
        local critical=$(awk -v warn="$CREATION_WARNING_MAX" \
            '$2 > warn {count++} END {print count}' "$file")
    else
        local optimal=$(awk -v min="$SUBMISSION_OPTIMAL_MIN" -v max="$SUBMISSION_OPTIMAL_MAX" \
            '$2 >= min && $2 <= max {count++} END {print count}' "$file")
        local warning=$(awk -v max="$SUBMISSION_OPTIMAL_MAX" -v warn="$SUBMISSION_WARNING_MAX" \
            '$2 > max && $2 <= warn {count++} END {print count}' "$file")
        local critical=$(awk -v warn="$SUBMISSION_WARNING_MAX" \
            '$2 > warn {count++} END {print count}' "$file")
    fi
    
    echo "$optimal $warning $critical"
}

# Temporary files
TEMP_CREATE=$(mktemp)
TEMP_SUBMIT=$(mktemp)

print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last ${BOLD}$TIME_WINDOW${RESET} minutes (${BOLD}$HOURS_AGO${RESET} hours)..."

# Extract creation and submission data with rounded integers
journalctl -u $SERVICE_NAME.service --since "$HOURS_AGO hours ago" | grep -F "creating data shard ring proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' | \
    awk '{printf "%d %d\n", $1, $2}' > "$TEMP_CREATE"

journalctl -u $SERVICE_NAME.service --since "$HOURS_AGO hours ago" | grep -F "submitting data proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' | \
    awk '{printf "%d %d\n", $1, $2}' > "$TEMP_SUBMIT"

# Calculate statistics if we have data
if [ -s "$TEMP_CREATE" ] && [ -s "$TEMP_SUBMIT" ]; then
    CREATE_STATS=($(calculate_percentages "$TEMP_CREATE" "creation"))
    SUBMIT_STATS=($(calculate_percentages "$TEMP_SUBMIT" "submission"))
    
    TOTAL_CREATES=$(wc -l < "$TEMP_CREATE")
    TOTAL_SUBMITS=$(wc -l < "$TEMP_SUBMIT")
    
   # Display results
    print_header "🔄 CREATION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_CREATES${RESET} creation events:"
    
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
    echo -e "${CRITICAL_COLOR}${BOLD}$CREATE_CRITICAL_PCT%${RESET} ${CRITICAL_COLOR}Ouch :-(${RESET} (>${CREATION_WARNING_MAX}s) - ${BOLD}${CREATE_STATS[2]}${RESET} proofs"

    # echo -e "${OPTIMAL_COLOR}${BOLD}$CREATE_OPTIMAL_PCT%${RESET} Optimal (${CREATION_OPTIMAL_MIN}-${CREATION_OPTIMAL_MAX}s) - ${BOLD}${CREATE_STATS[0]}${RESET} proofs"
    # echo -e "${WARNING_COLOR}${BOLD}$CREATE_WARNING_PCT%${RESET} Marginal (${CREATION_OPTIMAL_MAX}-${CREATION_WARNING_MAX}s) - ${BOLD}${CREATE_STATS[1]}${RESET} proofs"
    # echo -e "${CRITICAL_COLOR}${BOLD}$CREATE_CRITICAL_PCT%${RESET} Critical (>${CREATION_WARNING_MAX}s) - ${BOLD}${CREATE_STATS[2]}${RESET} proofs"

    
    print_header "📤 SUBMISSION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_SUBMITS${RESET} submission events:"
    
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
    echo -e "${CRITICAL_COLOR}${BOLD}$SUBMIT_CRITICAL_PCT%${RESET} ${CRITICAL_COLOR}Ouch :-(${RESET} (>${SUBMISSION_WARNING_MAX}s) - ${BOLD}${SUBMIT_STATS[2]}${RESET} proofs"
    
    # echo -e "${OPTIMAL_COLOR}${BOLD}$SUBMIT_OPTIMAL_PCT%${RESET} Optimal (${SUBMISSION_OPTIMAL_MIN}-${SUBMISSION_OPTIMAL_MAX}s) - ${BOLD}${SUBMIT_STATS[0]}${RESET} proofs"
    # echo -e "${WARNING_COLOR}${BOLD}$SUBMIT_WARNING_PCT%${RESET} Marginal (${SUBMISSION_OPTIMAL_MAX}-${SUBMISSION_WARNING_MAX}s) - ${BOLD}${SUBMIT_STATS[1]}${RESET} proofs"
    # echo -e "${CRITICAL_COLOR}${BOLD}$SUBMIT_CRITICAL_PCT%${RESET} Critical (>${SUBMISSION_WARNING_MAX}s) - ${BOLD}${SUBMIT_STATS[2]}${RESET} proofs"
    
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