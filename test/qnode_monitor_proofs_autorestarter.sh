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
    echo -e "${YELLOW}WARNING: Log directory does not exist. Creating $LOG_DIR...${NC}" | tee -a "$LOG_FILE"
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "ERROR: Failed to create log directory $LOG_DIR" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Function to log with timestamp and print to console
log_and_print() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"  # -e flag to interpret color codes
}

log_and_print "Checking proofs from the last 60 minutes..."

# Get all proof entries from the past 60 minutes
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "60 minutes ago" -r | \
              grep "proof batch.*increment")

# Count how many entries we got
entry_count=$(echo "$log_entries" | grep -c "proof batch")

# Check if we have any entries
if [ $entry_count -eq 0 ]; then
    log_and_print "${RED}Error: No proofs found in the last 60 minutes${NC}"
    log_and_print "Restarting ceremonyclient service..."
    log_and_print ""
    systemctl restart ceremonyclient
    exit 1
fi

# Get first and last increment values
first_increment=$(echo "$log_entries" | tail -n1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)
last_increment=$(echo "$log_entries" | head -n1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)

# Simple check: just verify if the overall trend is decreasing
if [ "$first_increment" -le "$last_increment" ]; then
    log_and_print "${RED}Error: Increments are not decreasing${NC}"
    log_and_print "First proof increment: $first_increment"
    log_and_print "Latest proof increment: $last_increment"
    log_and_print "Restarting ceremonyclient service..."
    log_and_print ""
    systemctl restart ceremonyclient
    exit 1
fi

log_and_print "Proof check passed:"
log_and_print "First proof increment: $first_increment"
log_and_print "Latest proof increment: $last_increment"
log_and_print "Total decrease: $((first_increment - last_increment))"
log_and_print "Number of proofs in last hour: $entry_count"
log_and_print ""

#####################
# Logs - clean
#####################

# At the end of script, rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

exit 0