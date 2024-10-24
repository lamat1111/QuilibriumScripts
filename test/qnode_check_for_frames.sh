#!/bin/bash

# Parse command line arguments
DIFF=600  # Default value for diff
LOG_FILE="$HOME/scripts/logs/qnode_check_for_frames.log"
MAX_LOG_ENTRIES=144

if [ -z "$QUIL_SERVICE_NAME" ]; then
    QUIL_SERVICE_NAME="ceremonyclient"
fi

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to rotate logs
rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        local line_count=$(wc -l < "$LOG_FILE")
        if [ "$line_count" -gt "$MAX_LOG_ENTRIES" ]; then
            local lines_to_keep=$((MAX_LOG_ENTRIES))
            local temp_file="${LOG_FILE}.tmp"
            tail -n $lines_to_keep "$LOG_FILE" > "$temp_file"
            mv "$temp_file" "$LOG_FILE"
            log_message "INFO" "Log rotated, keeping last $lines_to_keep entries"
        fi
    fi
}

# Error handling function
handle_error() {
    local error_message="$1"
    log_message "ERROR" "$error_message"
    echo "ERROR: $error_message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --diff)
            DIFF="$2"
            shift 2
            ;;
        *)
            handle_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_message "INFO" "Script started with diff: $DIFF seconds"

# Function to get the latest timestamp
get_latest_frame_received_timestamp() {
    journalctl -u $QUIL_SERVICE_NAME --no-hostname -g "received new leading frame" --output=cat -r -n 1 | jq -r '.ts'
}

get_latest_timestamp() {
    journalctl -u $QUIL_SERVICE_NAME --no-hostname --output=cat -r -n 1 | jq -r '.ts'
}

restart_application() {
    log_message "WARNING" "Initiating service restart for $QUIL_SERVICE_NAME"
    if service $QUIL_SERVICE_NAME restart; then
        log_message "INFO" "Service restart completed successfully"
    else
        handle_error "Failed to restart service $QUIL_SERVICE_NAME"
        exit 1
    fi
}

# Get the initial timestamp
last_timestamp=$(get_latest_frame_received_timestamp | awk '{print int($1)}')

if [ -z "$last_timestamp" ]; then
    handle_error "No frames received timestamp found in latest logs"
    log_message "WARNING" "Initiating restart due to missing timestamp"
    restart_application
    exit 1
fi

# Get the current timestamp
current_timestamp=$(get_latest_timestamp | awk '{print int($1)}')

log_message "INFO" "Last timestamp: $last_timestamp"
log_message "INFO" "Current timestamp: $current_timestamp"

# Calculate the time difference
time_diff=$(echo "$current_timestamp - $last_timestamp" | bc)

log_message "INFO" "Time difference: $time_diff seconds"

# If the time difference is more than $DIFF, restart the node
if [ $time_diff -gt $DIFF ]; then
    log_message "WARNING" "No new leading frame received in the last $DIFF seconds"
    restart_application
else
    log_message "INFO" "New leading frame received within the last $DIFF seconds. No action needed."
fi

# Rotate logs at the end of script execution
rotate_logs

exit 0