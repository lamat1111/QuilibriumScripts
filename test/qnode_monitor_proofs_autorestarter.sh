#!/bin/bash

# Color definitions for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SCRIPT_PATH="$0"
GITHUB_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/qnode_monitor_proofs_autorestarter.sh"


# Function to check for updates
check_for_update() {
    echo "Checking for updates..."
    
    # Download the remote script to a temporary file
    local temp_file="/tmp/qnode_monitor_update.sh"
    if ! curl -s -L "$GITHUB_URL" -o "$temp_file"; then
        echo -e "${YELLOW}Warning: Could not check for updates${NC}"
        return 1
    fi
    
    # Check if files are different
    if ! cmp -s "$SCRIPT_PATH" "$temp_file"; then
        echo -e "${GREEN}New version found. Updating...${NC}"
        # Copy the new version over the current script
        if cp "$temp_file" "$SCRIPT_PATH"; then
            # Make sure it's executable
            chmod +x "$SCRIPT_PATH"
            echo -e "${GREEN}Update successful. Restarting script...${NC}"
            # Clean up
            rm "$temp_file"
            # Execute the new version
            exec "$SCRIPT_PATH"
            # Exit the current script
            exit 0
        else
            echo -e "${RED}Error: Update failed${NC}"
        fi
    else
        echo "No updates found."
        rm "$temp_file"
    fi
}

# Run update check
check_for_update


# Check and update crontab if needed
check_and_update_crontab() {
    echo "Checking crontab configuration..."
    
    # Check if hourly cron exists
    if crontab -l 2>/dev/null | grep -q "0 \* \* \* \* .*qnode_monitor_proofs_autorestarter.sh"; then
        echo -e "${YELLOW}Found hourly cron schedule. Updating to run every 30 minutes...${NC}"
        
        # Replace hourly with every 30 minutes
        (crontab -l 2>/dev/null | grep -v "qnode_monitor_proofs_autorestarter.sh"; \
         echo "*/30 * * * * $SCRIPT_PATH") | crontab -
        
        echo -e "${GREEN}Crontab updated successfully${NC}"
    else
        # Check if 30-minute cron already exists
        if ! crontab -l 2>/dev/null | grep -q "qnode_monitor_proofs_autorestarter.sh"; then
            echo "No monitoring cron found. Adding 30-minute schedule..."
            (crontab -l 2>/dev/null; echo "*/30 * * * * $SCRIPT_PATH") | crontab -
            echo -e "${GREEN}Crontab entry added successfully${NC}"
        else
            echo "Correct crontab entry already exists"
        fi
    fi
}

# Run crontab check
check_and_update_crontab



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

log_and_print "Checking proofs from the last 30 minutes..."

# Get all proof entries from the past 30 minutes
log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "30 minutes ago" -r | \
              grep "proof batch.*increment")

# First, check for increment:0 message
if echo "$log_entries" | grep -q '"increment":0'; then
    log_and_print "=========================================="
    log_and_print "${GREEN}All proofs have been submitted!${NC}"
    log_and_print "=========================================="
    log_and_print "Removing monitoring crontab..."
    
    # Remove the crontab entry if it exists
    crontab -l | grep -v "qnode_monitor_proofs_autorestarter.sh" | crontab -
    
    log_and_print "Monitoring script will no longer run."
    log_and_print "=========================================="
    log_and_print ""
    exit 0
fi

# Count how many entries we got
entry_count=$(echo "$log_entries" | grep -c "proof batch")

# Check if we have any entries
if [ $entry_count -eq 0 ]; then
    log_and_print "${RED}Error: No proofs found in the last 30 minutes${NC}"
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
    log_and_print "First increment: $first_increment"
    log_and_print "Latest increment: $last_increment"
    log_and_print "Restarting ceremonyclient service..."
    log_and_print ""
    systemctl restart ceremonyclient
    exit 1
fi

# Output section
log_and_print "=========================================="
log_and_print "Proof check passed!"
log_and_print "=========================================="
log_and_print "First increment: $first_increment"
log_and_print "Latest increment: $last_increment"
log_and_print "------------------------------------------"
log_and_print "Total increment decrease: $((first_increment - last_increment))"
log_and_print "Number of batches: $(((first_increment - last_increment) / 200))"
log_and_print "Avg batch time: $(echo "scale=2; 30/$(((first_increment - last_increment) / 200))" | bc) minutes"
log_and_print "------------------------------------------"
log_and_print "Number of proof messages in last 30 minutes: $entry_count"
log_and_print "=========================================="
log_and_print ""

#####################
# Logs - clean
#####################

# At the end of script, rotate logs
tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

exit 0