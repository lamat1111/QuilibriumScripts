#!/bin/bash

# Description:
# This script analyzes proof creation and submission frame ages to determine
# likelihood of proofs landing successfully.
# It analyzes both "creating data shard ring proof" and "submitting data proof" events.
#
# Usage:  ~/scripts/qnode_proof_monitor.sh [minutes]
# Example:  ~/scripts/qnode_proof_monitor.sh 600    # analyzes last 10 hours

# Script version
SCRIPT_VERSION="4.1"

# Default time window in minutes (3 hours by default)
DEFAULT_TIME_WINDOW=180

# Get time window from command line argument or use default
TIME_WINDOW=${1:-$DEFAULT_TIME_WINDOW}

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

# CPU processing thresholds
CPU_OPTIMAL_MAX=20  # Optimal max CPU time
CPU_WARNING_MAX=30  # Warning max CPU time

# Colors and formatting
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
RESET='\033[0m'
GRAY='\033[38;5;244m'
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

# Helper function for section headers
print_header() {
    echo -e "\n${BOLD}${CYAN}$1${RESET}"
    echo -e "${CYAN}$SEPARATOR${RESET}"
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
        # Submission stage ranges
        local optimal=$(awk -v min="$SUBMISSION_OPTIMAL_MIN" -v max="$SUBMISSION_OPTIMAL_MAX" \
            '$1 >= min && $1 <= max {count++} END {print count+0}' "$file")
        local warning=$(awk -v max="$SUBMISSION_OPTIMAL_MAX" -v warn="$SUBMISSION_WARNING_MAX" \
            '$1 > max && $1 <= warn {count++} END {print count+0}' "$file")
        local critical=$(awk -v warn="$SUBMISSION_WARNING_MAX" \
            '$1 > warn {count++} END {print count+0}' "$file")
    fi
    
    echo "$optimal $warning $critical"
}

# Function to get latest ring and workers numbers
get_latest_stats() {
    local latest_log=$(journalctl -u $SERVICE_NAME.service --since "$TIME_WINDOW minutes ago" | grep -F "submitting data proof" | tail -n 1)
    local ring=$(echo "$latest_log" | grep -o '"ring":[0-9]\+' | cut -d':' -f2)
    local workers=$(echo "$latest_log" | grep -o '"active_workers":[0-9]\+' | cut -d':' -f2)
    
    # If empty, mark as unknown
    if [ -z "$workers" ]; then
        workers="unknown"
    fi
    
    echo "$ring $workers"
}

# Add these functions BEFORE they are called
get_cpu_info() {
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | xargs)
    local cpu_cores=$(nproc)
    local cpu_threads=$(grep -c processor /proc/cpuinfo)
    echo "$cpu_model|$cpu_cores|$cpu_threads"
}

get_ram_info() {
    local total_ram=$(free -g | awk '/^Mem:/ {printf "%.1f", $2}')
    echo "$total_ram"
}

# Check for updates
check_for_updates

print_header "📊 COLLECTING DATA"
echo -e "Analyzing proof submissions for the last ${BOLD}$TIME_WINDOW${RESET} minutes..."

# Temporary files
TEMP_CREATE=$(mktemp)
TEMP_SUBMIT=$(mktemp)
TEMP_CREATE_FRAMES=$(mktemp)
TEMP_SUBMIT_FRAMES=$(mktemp)
TEMP_MATCHES=$(mktemp)

# Extract frame ages (not frame numbers) for statistics
journalctl -u $SERVICE_NAME.service --since "$TIME_WINDOW minutes ago" | \
    grep -F "creating data shard ring proof" | \
    sed -E 's/.*"frame_age":([0-9]+\.[0-9]+).*/\1/' > "$TEMP_CREATE"

journalctl -u $SERVICE_NAME.service --since "$TIME_WINDOW minutes ago" | \
    grep -F "submitting data proof" | \
    sed -E 's/.*"frame_age":([0-9]+\.[0-9]+).*/\1/' > "$TEMP_SUBMIT"

# Extract frame numbers AND ages for CPU time calculation
journalctl -u $SERVICE_NAME.service --since "$TIME_WINDOW minutes ago" | \
    grep -F "creating data shard ring proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' > "$TEMP_CREATE_FRAMES"

journalctl -u $SERVICE_NAME.service --since "$TIME_WINDOW minutes ago" | \
    grep -F "submitting data proof" | \
    sed -E 's/.*"frame_number":([0-9]+).*"frame_age":([0-9]+\.[0-9]+).*/\1 \2/' > "$TEMP_SUBMIT_FRAMES"

# DEBUG STARTS

# echo -e "\n${CYAN}=== DEBUG: Extracted Frame Data ===${RESET}"
# echo -e "\n${BOLD}Sample of creation frames (first 5 lines):${RESET}"
# head -n 5 "$TEMP_CREATE_FRAMES"

# echo -e "\n${BOLD}Sample of submission frames (first 5 lines):${RESET}"
# head -n 5 "$TEMP_SUBMIT_FRAMES"

# echo -e "\n${CYAN}=== DEBUG: First 5 CPU Time Calculations ===${RESET}"
# COUNTER=0
# while read -r create_line; do
#     if [ $COUNTER -lt 5 ]; then
#         echo -e "\n${BOLD}Processing creation line:${RESET} $create_line"
        
#         create_frame=$(echo "$create_line" | cut -d' ' -f1)
#         create_age=$(echo "$create_line" | cut -d' ' -f2)
#         echo "Frame: $create_frame, Creation Age: $create_age"
        
#         submit_line=$(grep "^$create_frame " "$TEMP_SUBMIT_FRAMES")
#         if [ ! -z "$submit_line" ]; then
#             echo "Found matching submission: $submit_line"
#             submit_age=$(echo "$submit_line" | cut -d' ' -f2)
#             echo "Submission Age: $submit_age"
            
#             cpu_time=$(awk "BEGIN {printf \"%.2f\", $submit_age - $create_age}")
#             echo "${YELLOW}CPU Time calculation: $submit_age - $create_age = $cpu_time${RESET}"
#             echo "$cpu_time" >> "$TEMP_MATCHES"
#         else
#             echo "No matching submission found for frame $create_frame"
#         fi
#         echo "----------------------------------------"
#         COUNTER=$((COUNTER + 1))
#     else
#         break  # Exit the debug loop after 5 iterations
#     fi
# done < "$TEMP_CREATE_FRAMES"

# # Reset for actual processing
# rm -f "$TEMP_MATCHES"

# DEBUG ENDS

# Calculate CPU Processing Time
while read -r create_line; do
    create_frame=$(echo "$create_line" | cut -d' ' -f1)
    create_age=$(echo "$create_line" | cut -d' ' -f2)
    
    submit_line=$(grep "^$create_frame " "$TEMP_SUBMIT_FRAMES")
    if [ ! -z "$submit_line" ]; then
        submit_age=$(echo "$submit_line" | cut -d' ' -f2)
        cpu_time=$(awk "BEGIN {printf \"%.2f\", $submit_age - $create_age}")
        echo "$cpu_time" >> "$TEMP_MATCHES"
    fi
done < "$TEMP_CREATE_FRAMES"

# Calculate statistics if we have data
if [ -s "$TEMP_CREATE" ] && [ -s "$TEMP_SUBMIT" ]; then
    CREATE_STATS=($(calculate_percentages "$TEMP_CREATE" "creation"))
    SUBMIT_STATS=($(calculate_percentages "$TEMP_SUBMIT" "submission"))
    NODE_STATS=($(get_latest_stats))
    
    CREATE_AGE_STATS=($(calculate_stats "$TEMP_CREATE"))
    SUBMIT_AGE_STATS=($(calculate_stats "$TEMP_SUBMIT"))
    
    TOTAL_CREATES=$(wc -l < "$TEMP_CREATE")
    TOTAL_SUBMITS=$(wc -l < "$TEMP_SUBMIT")

    # Creation Stage Analysis
    print_header "🔄 CREATION STAGE ANALYSIS (Network Latency)"
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
    
    echo -e "\n${GRAY}Average Frame Age: ${BOLD}${CREATE_AGE_STATS[0]}s${RESET}"
    echo -e "${GRAY}Standard Deviation: ${BOLD}${CREATE_AGE_STATS[1]}s${RESET}"
    echo -e "${GRAY}Lowest Frame Age: ${BOLD}${CREATE_AGE_STATS[2]}s${RESET}"
    echo -e "${GRAY}Highest Frame Age: ${BOLD}${CREATE_AGE_STATS[3]}s${RESET}${RESET}"
    
    # Submission Stage Analysis
    print_header "📤 SUBMISSION STAGE ANALYSIS (Total Time)"
    echo -e "Distribution of ${BOLD}$TOTAL_SUBMITS${RESET} submission events:\n"
    
    SUBMIT_OPTIMAL_PCT=$(( SUBMIT_STATS[0] * 100 / TOTAL_SUBMITS ))
    SUBMIT_WARNING_PCT=$(( SUBMIT_STATS[1] * 100 / TOTAL_SUBMITS ))
    SUBMIT_CRITICAL_PCT=$(( SUBMIT_STATS[2] * 100 / TOTAL_SUBMITS ))
    
    # Reset colors
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
    echo -e "${GRAY}Standard Deviation: ${BOLD}${SUBMIT_AGE_STATS[1]}s${RESET}"
    echo -e "${GRAY}Lowest Frame Age: ${BOLD}${SUBMIT_AGE_STATS[2]}s${RESET}"
    echo -e "${GRAY}Highest Frame Age: ${BOLD}${SUBMIT_AGE_STATS[3]}s${RESET}${RESET}"

    # CPU Processing Time Analysis (only if we have matches)
    if [ -s "$TEMP_MATCHES" ]; then
        CPU_AGE_STATS=($(calculate_stats "$TEMP_MATCHES"))
        TOTAL_MATCHES=$(wc -l < "$TEMP_MATCHES")
        
        # Calculate percentages for CPU processing time
        CPU_STATS=($(awk -v opt_max="$CPU_OPTIMAL_MAX" -v warn_max="$CPU_WARNING_MAX" '
            {
                if ($1 <= opt_max) optimal++
                else if ($1 <= warn_max) warning++
                else critical++
            }
            END {
                print optimal+0, warning+0, critical+0
            }' "$TEMP_MATCHES"))
        
        print_header "⚡ CPU PROCESSING TIME ANALYSIS (Processing Only)"
        echo -e "Distribution of ${BOLD}$TOTAL_MATCHES${RESET} matched proof events:\n"
        
        CPU_OPTIMAL_PCT=$(( CPU_STATS[0] * 100 / TOTAL_MATCHES ))
        CPU_WARNING_PCT=$(( CPU_STATS[1] * 100 / TOTAL_MATCHES ))
        CPU_CRITICAL_PCT=$(( CPU_STATS[2] * 100 / TOTAL_MATCHES ))
        
        # Reset colors
        OPTIMAL_COLOR=""
        WARNING_COLOR=""
        CRITICAL_COLOR=""
        
        (( CPU_OPTIMAL_PCT > 50 )) && OPTIMAL_COLOR=$GREEN
        (( CPU_WARNING_PCT > 50 )) && WARNING_COLOR=$YELLOW
        (( CPU_CRITICAL_PCT > 50 )) && CRITICAL_COLOR=$RED

        echo -e "${OPTIMAL_COLOR}${BOLD}$CPU_OPTIMAL_PCT%${RESET} ${OPTIMAL_COLOR}Good!${RESET} (≤${CPU_OPTIMAL_MAX}s) - ${BOLD}${CPU_STATS[0]}${RESET} proofs"
        echo -e "${WARNING_COLOR}${BOLD}$CPU_WARNING_PCT%${RESET} ${WARNING_COLOR}Meh...${RESET} (${CPU_OPTIMAL_MAX}-${CPU_WARNING_MAX}s) - ${BOLD}${CPU_STATS[1]}${RESET} proofs"
        echo -e "${CRITICAL_COLOR}${BOLD}$CPU_CRITICAL_PCT%${RESET} ${CRITICAL_COLOR}Ouch!${RESET} (>${CPU_WARNING_MAX}s) - ${BOLD}${CPU_STATS[2]}${RESET} proofs"
        
        echo -e "\n${GRAY}Average Processing Time: ${BOLD}${CPU_AGE_STATS[0]}s${RESET}"
        echo -e "${GRAY}Standard Deviation: ${BOLD}${CPU_AGE_STATS[1]}s${RESET}"
        echo -e "${GRAY}Fastest Processing: ${BOLD}${CPU_AGE_STATS[2]}s${RESET}"
        echo -e "${GRAY}Slowest Processing: ${BOLD}${CPU_AGE_STATS[3]}s${RESET}${RESET}"
        
        if (( CPU_CRITICAL_PCT > 50 )); then
            echo -e "\n${RED}${BOLD}WARNING:${RESET} Most proofs are taking longer than ${CPU_OPTIMAL_MAX}s to process."
            echo -e "This may significantly impact your ability to earn rewards."
        fi
    fi
    
    # Overall health assessment
    print_header "📋 OVERALL HEALTH ASSESSMENT"
    
    # Check if we have CPU data
    if [ -s "$TEMP_MATCHES" ]; then
        # Calculate majority percentages for each section
        CREATE_MAJORITY_PCT=$(( CREATE_OPTIMAL_PCT > 50 ? 1 : CREATE_WARNING_PCT > 50 ? 2 : CREATE_CRITICAL_PCT > 50 ? 3 : 0 ))
        SUBMIT_MAJORITY_PCT=$(( SUBMIT_OPTIMAL_PCT > 50 ? 1 : SUBMIT_WARNING_PCT > 50 ? 2 : SUBMIT_CRITICAL_PCT > 50 ? 3 : 0 ))
        CPU_MAJORITY_PCT=$(( CPU_OPTIMAL_PCT > 50 ? 1 : CPU_WARNING_PCT > 50 ? 2 : CPU_CRITICAL_PCT > 50 ? 3 : 0 ))
        
        # Evaluate overall health
        if [ $CREATE_MAJORITY_PCT -eq 1 ] && [ $SUBMIT_MAJORITY_PCT -eq 1 ] && [ $CPU_MAJORITY_PCT -eq 1 ]; then
            echo -e "Status: ${GREEN}${BOLD}OPTIMAL${RESET} 🟢"
            echo -e "All metrics show excellent performance. System is running ideally."
        elif [ $CREATE_MAJORITY_PCT -eq 3 ] && [ $SUBMIT_MAJORITY_PCT -eq 3 ] && [ $CPU_MAJORITY_PCT -eq 3 ]; then
            echo -e "Status: ${RED}${BOLD}CRITICAL${RESET} 🔴"
            echo -e "All metrics show critical performance issues. System needs immediate attention."
        else
            echo -e "Status: ${YELLOW}${BOLD}SUBOPTIMAL${RESET} 🟡"
            echo -e "Mixed performance metrics. System may need optimization."
        fi
    else
        # Evaluation without CPU data
        CREATE_MAJORITY_PCT=$(( CREATE_OPTIMAL_PCT > 50 ? 1 : CREATE_WARNING_PCT > 50 ? 2 : CREATE_CRITICAL_PCT > 50 ? 3 : 0 ))
        SUBMIT_MAJORITY_PCT=$(( SUBMIT_OPTIMAL_PCT > 50 ? 1 : SUBMIT_WARNING_PCT > 50 ? 2 : SUBMIT_CRITICAL_PCT > 50 ? 3 : 0 ))
        
        if [ $CREATE_MAJORITY_PCT -eq 1 ] && [ $SUBMIT_MAJORITY_PCT -eq 1 ]; then
            echo -e "Status: ${GREEN}${BOLD}OPTIMAL${RESET} 🟢"
            echo -e "All metrics show excellent performance. System is running ideally."
        elif [ $CREATE_MAJORITY_PCT -eq 3 ] && [ $SUBMIT_MAJORITY_PCT -eq 3 ]; then
            echo -e "Status: ${RED}${BOLD}CRITICAL${RESET} 🔴"
            echo -e "All metrics show critical performance issues. System needs immediate attention."
        else
            echo -e "Status: ${YELLOW}${BOLD}SUBOPTIMAL${RESET} 🟡"
            echo -e "Mixed performance metrics. System may need optimization."
        fi
    fi
    
    # System information section
    print_header "💻 NODE & SYSTEM INFORMATION"

    echo -e "Ring: ${NODE_STATS[0]}"
    echo -e "Workers: ${NODE_STATS[1]}"

    # Get CPU and RAM info
    IFS='|' read -r cpu_model cpu_cores cpu_threads <<< "$(get_cpu_info)"
    ram_gb=$(get_ram_info)

    echo -e "\nCPU Model: $cpu_model"
    echo -e "CPU Cores: $cpu_cores ($cpu_threads threads)"
    echo -e "Total RAM: ${ram_gb} GB"
    
else
    echo -e "\n${RED}${BOLD}No proofs found in the last $TIME_WINDOW minutes${RESET}"
fi

# Cleanup
rm -f "$TEMP_CREATE" "$TEMP_SUBMIT" "$TEMP_CREATE_FRAMES" "$TEMP_SUBMIT_FRAMES" "$TEMP_MATCHES"

# Print footer with optimal ranges and usage
print_header "ℹ️ USAGE INFO"
echo -e "Optimal ranges:"
echo -e "Creation stage:  ${BOLD}$CREATION_OPTIMAL_MIN-$CREATION_OPTIMAL_MAX${RESET} seconds (network latency)"
echo -e "Submission stage: ${BOLD}$SUBMISSION_OPTIMAL_MIN-$SUBMISSION_OPTIMAL_MAX${RESET} seconds (total time)"
echo -e "CPU processing: ${BOLD}≤${CPU_OPTIMAL_MAX}${RESET} seconds (submission - creation)"
echo -e "\nTo analyze a different time window:"
echo -e "$HOME/scripts/qnode_proof_monitor.sh [minutes]"
echo -e "Example: $HOME/scripts/qnode_proof_monitor.sh 600  # analyzes last 10 hours"
echo -e "\nv $SCRIPT_VERSION"
echo