#!/bin/bash

# Color definitions for output
RED='\033[0;31m'
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

# Get the last 2 proof entries from the past 60 minutes
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "60 minutes ago" -r | \
              grep "proof batch.*increment" | \
              head -n 2 | \
              tac)

# Count how many entries we got
entry_count=$(echo "$log_entries" | grep -c "proof batch")

# Check if we have at least 2 entries
if [ $entry_count -lt 2 ]; then
    echo -e "${RED}Error: Less than 2 proofs found in the last 60 minutes${NC}"
    echo "Restarting ceremonyclient service..."
    echo
    systemctl restart ceremonyclient
    exit 1
fi

# Extract increments from both entries
first_increment=$(echo "$log_entries" | head -n 1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)
second_increment=$(echo "$log_entries" | tail -n 1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)

# Check if increment is decreasing
if [ $first_increment -le $second_increment ]; then
    echo -e "${RED}Error: Increment is not decreasing${NC}"
    echo "First increment: $first_increment"
    echo "Second increment: $second_increment"
    echo "Restarting ceremonyclient service..."
    echo
    systemctl restart ceremonyclient
    exit 1
fi

echo "Proof check passed:"
echo "First increment: $first_increment"
echo "Second increment: $second_increment"
echo "Increment decreased by: $((first_increment - second_increment))"
echo
exit 0

#####################
# Logs - clean
#####################

# At the end of script, rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"