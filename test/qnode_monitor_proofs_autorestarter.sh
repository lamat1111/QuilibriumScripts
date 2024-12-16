#!/bin/bash

# Color definitions for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SCRIPT_PATH="$0"
GITHUB_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/qnode_monitor_proofs_autorestarter.sh"

# Log configuration
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/qnode_monitor_proofs.log"
LOG_ENTRIES=1000

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check for updates
check_for_update() {
    print_message "$NC" "Checking for updates..."
    
    local temp_file="/tmp/qnode_monitor_update.sh"
    if ! curl -s -L "$GITHUB_URL" -o "$temp_file"; then
        print_message "$YELLOW" "Warning: Could not check for updates"
        return 1
    }
    
    if ! cmp -s "$SCRIPT_PATH" "$temp_file"; then
        print_message "$GREEN" "New version found. Updating..."
        if cp "$temp_file" "$SCRIPT_PATH"; then
            chmod +x "$SCRIPT_PATH"
            print_message "$GREEN" "Update successful. Restarting script..."
            rm "$temp_file"
            exec "$SCRIPT_PATH"
            exit 0
        else
            print_message "$RED" "Error: Update failed"
        fi
    else
        print_message "$NC" "No updates found."
        rm "$temp_file"
    fi
}

# Function to check for and remove monitoring cronjob
check_and_remove_crontab() {
    print_message "$YELLOW" "Checking for existing monitoring cronjob..."
    
    if crontab -l 2>/dev/null | grep -q "qnode_monitor_proofs_autorestarter.sh"; then
        print_message "$YELLOW" "Found existing cronjob. Removing..."
        crontab -l 2>/dev/null | grep -v "qnode_monitor_proofs_autorestarter.sh" | crontab -
        print_message "$GREEN" "Successfully removed monitoring cronjob."
    else
        print_message "$GREEN" "No existing monitoring cronjob found."
    fi
}

# Function to add monitoring cronjob
add_monitoring_crontab() {
    print_message "$NC" "Checking crontab configuration..."
    
    if crontab -l 2>/dev/null | grep -q "0 \* \* \* \* .*qnode_monitor_proofs_autorestarter.sh"; then
        print_message "$YELLOW" "Found hourly cron schedule. Updating to run every 30 minutes..."
        (crontab -l 2>/dev/null | grep -v "qnode_monitor_proofs_autorestarter.sh"; \
         echo "*/30 * * * * $SCRIPT_PATH") | crontab -
        print_message "$GREEN" "Crontab updated successfully"
    else
        if ! crontab -l 2>/dev/null | grep -q "qnode_monitor_proofs_autorestarter.sh"; then
            print_message "$NC" "No monitoring cron found. Adding 30-minute schedule..."
            (crontab -l 2>/dev/null; echo "*/30 * * * * $SCRIPT_PATH") | crontab -
            print_message "$GREEN" "Crontab entry added successfully"
        else
            print_message "$NC" "Correct crontab entry already exists"
        fi
    fi
}

# Function to setup logging
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        print_message "$YELLOW" "WARNING: Log directory does not exist. Creating $LOG_DIR..." | tee -a "$LOG_FILE"
        if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
            print_message "$RED" "ERROR: Failed to create log directory $LOG_DIR" | tee -a "$LOG_FILE"
            exit 1
        fi
    fi
}

# Function to log with timestamp and print to console
log_and_print() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(echo "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
    echo -e "$1"
}

# Function to check proofs
check_proofs() {
    log_and_print "Checking proofs from the last 30 minutes..."

    local log_entries=$(journalctl -u ceremonyclient.service --no-hostname --since "30 minutes ago" -r | \
                       grep "proof batch.*increment")

    if echo "$log_entries" | grep -q '"increment":0'; then
        log_and_print "=========================================="
        log_and_print "${GREEN}All proofs have been submitted!${NC}"
        log_and_print "=========================================="
        log_and_print "Removing monitoring crontab..."
        
        check_and_remove_crontab
        
        log_and_print "Monitoring script will no longer run."
        log_and_print "=========================================="
        log_and_print ""
        exit 0
    fi

    local entry_count=$(echo "$log_entries" | grep -c "proof batch")

    if [ $entry_count -eq 0 ]; then
        log_and_print "Error: No proofs found in the last 30 minutes"
        log_and_print "Restarting ceremonyclient service..."
        log_and_print ""
        systemctl restart ceremonyclient
        exit 1
    fi

    local first_increment=$(echo "$log_entries" | tail -n1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)
    local last_increment=$(echo "$log_entries" | head -n1 | grep -o '"increment":[0-9]*' | cut -d':' -f2)

    if [ "$first_increment" -le "$last_increment" ]; then
        log_and_print "Error: Increments are not decreasing"
        log_and_print "First increment: $first_increment"
        log_and_print "Latest increment: $last_increment"
        log_and_print "Restarting ceremonyclient service..."
        log_and_print ""
        systemctl restart ceremonyclient
        exit 1
    fi

    log_and_print "=========================================="
    log_and_print "Proof check passed!"
    log_and_print "=========================================="
    log_and_print "First increment: $first_increment"
    log_and_print "Latest increment: $last_increment"
    log_and_print "------------------------------------------"
    log_and_print "Total increment decrease: $((first_increment - last_increment))"
    log_and_print "Number of batches: $(((first_increment - last_increment) / 200))"
    log_and_print "Avg batch time: $(echo "scale=2; (30*60)/$(((first_increment - last_increment) / 200))" | bc) seconds"
    log_and_print "------------------------------------------"
    log_and_print "Proof messages: $entry_count"
    log_and_print "=========================================="
    log_and_print ""
}

# Function to rotate logs
rotate_logs() {
    tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
}

# Main function
main() {
    # Check if we just want to remove the cronjob
    if [ "$1" = "remove_cron" ]; then
        check_and_remove_crontab
        exit 0
    fi

    # Regular script execution
    check_for_update
    #setup_logging
    #check_proofs
    #rotate_logs
}

# Run the script with command line arguments
main