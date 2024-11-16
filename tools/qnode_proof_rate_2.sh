#!/bin/bash

# [Previous service configuration and formatting code remains the same until the analysis part]

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

# [Previous data collection code remains the same until the analysis part]

if [ -s "$TEMP_CREATE" ] && [ -s "$TEMP_SUBMIT" ]; then
    CREATE_STATS=($(calculate_percentages "$TEMP_CREATE" "creation"))
    SUBMIT_STATS=($(calculate_percentages "$TEMP_SUBMIT" "submission"))
    
    TOTAL_CREATES=$(wc -l < "$TEMP_CREATE")
    TOTAL_SUBMITS=$(wc -l < "$TEMP_SUBMIT")
    
    # Display results
    print_header "🔄 CREATION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_CREATES${RESET} creation events:"
    echo -e "${GREEN}${BOLD}$(( CREATE_STATS[0] * 100 / TOTAL_CREATES ))%${RESET} Optimal (${CREATION_OPTIMAL_MIN}-${CREATION_OPTIMAL_MAX}s)"
    echo -e "${YELLOW}${BOLD}$(( CREATE_STATS[1] * 100 / TOTAL_CREATES ))%${RESET} Warning (${CREATION_OPTIMAL_MAX}-${CREATION_WARNING_MAX}s)"
    echo -e "${RED}${BOLD}$(( CREATE_STATS[2] * 100 / TOTAL_CREATES ))%${RESET} Critical (>${CREATION_WARNING_MAX}s)"
    
    print_header "📤 SUBMISSION STAGE ANALYSIS"
    echo -e "Distribution of ${BOLD}$TOTAL_SUBMITS${RESET} submission events:"
    echo -e "${GREEN}${BOLD}$(( SUBMIT_STATS[0] * 100 / TOTAL_SUBMITS ))%${RESET} Optimal (${SUBMISSION_OPTIMAL_MIN}-${SUBMISSION_OPTIMAL_MAX}s)"
    echo -e "${YELLOW}${BOLD}$(( SUBMIT_STATS[1] * 100 / TOTAL_SUBMITS ))%${RESET} Warning (${SUBMISSION_OPTIMAL_MAX}-${SUBMISSION_WARNING_MAX}s)"
    echo -e "${RED}${BOLD}$(( SUBMIT_STATS[2] * 100 / TOTAL_SUBMITS ))%${RESET} Critical (>${SUBMISSION_WARNING_MAX}s)"
    
    # Overall health assessment
    print_header "📋 OVERALL HEALTH ASSESSMENT"
    CREATE_OPTIMAL_PCT=$(( CREATE_STATS[0] * 100 / TOTAL_CREATES ))
    SUBMIT_OPTIMAL_PCT=$(( SUBMIT_STATS[0] * 100 / TOTAL_SUBMITS ))
    
    if (( CREATE_OPTIMAL_PCT >= 70 && SUBMIT_OPTIMAL_PCT >= 70 )); then
        echo -e "Status: ${GREEN}${BOLD}HEALTHY${RESET} 🟢"
        echo -e "Most of your proofs are within optimal ranges and likely to land successfully"
    elif (( CREATE_OPTIMAL_PCT + $(( CREATE_STATS[1] * 100 / TOTAL_CREATES )) >= 70 )); then
        echo -e "Status: ${YELLOW}${BOLD}SUBOPTIMAL${RESET} 🟡"
        echo -e "Some proofs may not land successfully. Consider checking system resources."
    else
        echo -e "Status: ${RED}${BOLD}CRITICAL${RESET} 🔴"
        echo -e "Many proofs are outside optimal ranges. System may need attention."
    fi
fi

# [Rest of the cleanup and footer code remains the same]