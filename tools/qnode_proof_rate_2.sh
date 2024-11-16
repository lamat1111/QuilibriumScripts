#!/bin/bash

# Description:
# This script analyzes proof creation and submission frame ages to determine
# likelihood of proofs landing successfully.
# It analyzes both "creating data shard ring proof" and "submitting data proof" events.

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

# Helper function for section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${RESET}"
    echo -e "${BLUE}$SEPARATOR${RESET}"
}

# Helper function for values with units
format_value() {
    local value=$1
    local unit=$2
    printf "${BOLD}%9d${RESET} ${CYAN}%-10s${RESET}" "$value" "$unit"
}

# Helper function to categorize frame age
categorize_frame_age() {
    local stage=$1
    local age=$2
    
    if [ "$stage" = "creation" ]; then
        if (( age >= CREATION_OPTIMAL_MIN && age <= CREATION_OPTIMAL_MAX )); then
            echo "${GREEN}OPTIMAL${RESET}"
        elif (( age > CREATION_OPTIMAL_MAX && age <= CREATION_WARNING_MAX )); then
            echo "${YELLOW}WARNING${RESET}"
        else
            echo "${RED}CRITICAL${RESET}"
        fi
    else  # submission stage
        if (( age >= SUBMISSION_OPTIMAL_MIN && age <= SUBMISSION_OPTIMAL_MAX )); then
            echo "${GREEN}OPTIMAL${RESET}"
        elif (( age > SUBMISSION_OPTIMAL_MAX && age <= SUBMISSION_WARNING_MAX )); then
            echo "${YELLOW}WARNING${RESET}"
        else
            echo "${RED}CRITICAL${RESET}"
        fi
    fi
}

# Temporary files
TEMP_CREATE=$(mktemp)
TEMP_SUBMIT=$(mktemp)

print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last hour..."

# Extract creation and submission data with rounded integers
journalctl -u $SERVICE_NAME.service --since "1 hour ago" | grep -F "creating data shard ring proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' | \
    awk '{printf "%d %d\n", $1, $2}' > "$TEMP_CREATE"

journalctl -u $SERVICE_NAME.service --since "1 hour ago" | grep -F "submitting data proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' | \
    awk '{printf "%d %d\n", $1, $2}' > "$TEMP_SUBMIT"

# Calculate statistics if we have data
if [ -s "$TEMP_CREATE" ] && [ -s "$TEMP_SUBMIT" ]; then
    # Calculate averages and ranges (rounded to integers)
    CREATE_AVG=$(awk '{ sum += $2 } END { printf "%d", sum/NR }' "$TEMP_CREATE")
    SUBMIT_AVG=$(awk '{ sum += $2 } END { printf "%d", sum/NR }' "$TEMP_SUBMIT")
    
    CREATE_MIN=$(awk 'NR==1{min=$2;next}{if($2<min){min=$2}}END{printf "%d", min}' "$TEMP_CREATE")
    CREATE_MAX=$(awk 'NR==1{max=$2;next}{if($2>max){max=$2}}END{printf "%d", max}' "$TEMP_CREATE")
    
    SUBMIT_MIN=$(awk 'NR==1{min=$2;next}{if($2<min){min=$2}}END{printf "%d", min}' "$TEMP_SUBMIT")
    SUBMIT_MAX=$(awk 'NR==1{max=$2;next}{if($2>max){max=$2}}END{printf "%d", max}' "$TEMP_SUBMIT")
    
    # Calculate counts
    TOTAL_CREATES=$(wc -l < "$TEMP_CREATE")
    TOTAL_SUBMITS=$(wc -l < "$TEMP_SUBMIT")
    
    # Display results
    print_header "🔄 CREATION STAGE ANALYSIS"
    echo -e "Average Frame Age: $(format_value $CREATE_AVG "seconds") $(categorize_frame_age "creation" $CREATE_AVG)"
    echo -e "Range:            ${BOLD}$CREATE_MIN${RESET} to ${BOLD}$CREATE_MAX${RESET} seconds"
    
    print_header "📤 SUBMISSION STAGE ANALYSIS"
    echo -e "Average Frame Age: $(format_value $SUBMIT_AVG "seconds") $(categorize_frame_age "submission" $SUBMIT_AVG)"
    echo -e "Range:            ${BOLD}$SUBMIT_MIN${RESET} to ${BOLD}$SUBMIT_MAX${RESET} seconds"
    
    # Overall health assessment
    print_header "📋 OVERALL HEALTH ASSESSMENT"
    if (( CREATE_AVG <= CREATION_OPTIMAL_MAX && SUBMIT_AVG <= SUBMISSION_OPTIMAL_MAX )); then
        echo -e "Status: ${GREEN}${BOLD}HEALTHY${RESET} 🟢"
        echo -e "Your proofs are likely to land successfully"
    elif (( CREATE_AVG <= CREATION_WARNING_MAX && SUBMIT_AVG <= SUBMISSION_WARNING_MAX )); then
        echo -e "Status: ${YELLOW}${BOLD}SUBOPTIMAL${RESET} 🟡"
        echo -e "Some proofs may not land successfully"
    else
        echo -e "Status: ${RED}${BOLD}CRITICAL${RESET} 🔴"
        echo -e "Most proofs are unlikely to land successfully"
    fi
    
    echo -e "\nProofs analyzed:"
    echo -e "Creation events:  ${BOLD}$TOTAL_CREATES${RESET}"
    echo -e "Submission events: ${BOLD}$TOTAL_SUBMITS${RESET}"
else
    echo -e "\n${RED}${BOLD}No proofs found in the last hour${RESET}"
fi

# Cleanup
rm -f "$TEMP_CREATE" "$TEMP_SUBMIT"

# Print footer with optimal ranges
print_header "ℹ️ OPTIMAL RANGES"
echo -e "Creation stage:  ${BOLD}$CREATION_OPTIMAL_MIN-$CREATION_OPTIMAL_MAX${RESET} seconds"
echo -e "Submission stage: ${BOLD}$SUBMISSION_OPTIMAL_MIN-$SUBMISSION_OPTIMAL_MAX${RESET} seconds"