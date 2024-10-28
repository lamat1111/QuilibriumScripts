#!/bin/bash

# Color definitions for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#####################
# Logs - add
#####################

# Log configuration
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/qnode_monitor_proofs.log"
LOG_ENTRIES=1000

# Create log directory if needed
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}WARNING: Log directory does not exist. Creating $LOG_DIR...${NC}"
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "ERROR: Failed to create log directory $LOG_DIR"
        exit 1
    fi
fi

# Set up logging with timestamps
exec 1> >(while read line; do echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1

echo "Checking proofs from the last 60 minutes..."

# Get all proof entries from the past 60 minutes
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "60 minutes ago" -r | \
              grep "proof batch.*increment" | \
              tac)

# Count how many entries we got
entry_count=$(echo "$log_entries" | grep -c "proof batch")

# Check if we have any entries
if [ $entry_count -eq 0 ]; then
    echo -e "${RED}Error: No proofs found in the last 60 minutes${NC}"
    echo "Restarting ceremonyclient service..."
    echo
    systemctl restart ceremonyclient
    exit 1
fi

# Extract all increments and store them in an array
declare -a increments
while read -r line; do
    if [[ $line =~ \"increment\":([0-9]*) ]]; then
        increments+=(${BASH_REMATCH[1]})
    fi
done <<< "$log_entries"

# Print number of proofs found
echo "Found $entry_count proofs in the last 60 minutes"

# Function to check if increments are decreasing overall
# Returns 0 if trend is decreasing, 1 if not
check_decreasing_trend() {
    local len=${#increments[@]}
    local first_value=${increments[0]}
    local last_value=${increments[$((len-1))]}
    
    # First check overall trend from first to last value
    if [ $first_value -lt $last_value ]; then
        return 1
    fi
    
    # Then check for any significant increases in the sequence
    local prev_value=${increments[0]}
    local equal_count=0
    local max_equal_allowed=3  # Allow up to 3 consecutive equal values
    
    for ((i=1; i<len; i++)); do
        current_value=${increments[$i]}
        
        if [ $current_value -gt $prev_value ]; then
            # If we find any increase, that's a problem
            return 1
        elif [ $current_value -eq $prev_value ]; then
            # Count consecutive equal values
            ((equal_count++))
            if [ $equal_count -gt $max_equal_allowed ]; then
                # Too many consecutive equal values
                return 1
            fi
        else
            # Reset equal count when we see a decrease
            equal_count=0
        fi
        
        prev_value=$current_value
    done
    
    return 0
}

# Check the trend
if ! check_decreasing_trend; then
    echo -e "${RED}Error: Increments are not showing a consistent decreasing trend${NC}"
    echo "First increment: ${increments[0]}"
    echo "Last increment: ${increments[$((${#increments[@]}-1))]}"
    echo "Increment sequence:"
    printf '%s\n' "${increments[@]}"
    echo "Restarting ceremonyclient service..."
    echo
    systemctl restart ceremonyclient
    exit 1
fi

echo "Proof check passed:"
echo "First increment: ${increments[0]}"
echo "Last increment: ${increments[$((${#increments[@]}-1))]}"
echo "Total decrease: $((increments[0] - increments[$((${#increments[@]}-1))]))"
echo "Number of proofs analyzed: ${#increments[@]}"
echo

exit 0

#####################
# Logs - clean
#####################

# At the end of script, rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"