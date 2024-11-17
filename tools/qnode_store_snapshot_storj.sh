#!/bin/bash

#####################
# Logs - Configuration
#####################

# Log configuration
LOG_DIR="$HOME/scripts/logs"
LOG_FILE="$LOG_DIR/qnode_store_snapshot.log"
LOG_ENTRIES=1000

# Create log directory if needed
if [ ! -d "$LOG_DIR" ]; then
    echo "Log directory does not exist. Creating $LOG_DIR..."
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "ERROR: Failed to create log directory $LOG_DIR"
        exit 1
    fi
fi

# Set up logging with timestamps
exec 1> >(while read line; do echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1

#####################
# Backup store folder
#####################

echo "Starting Quilibrium node store backup process"

# Stop the ceremony client service
echo "Stopping ceremonyclient service..."
if ! systemctl stop ceremonyclient; then
    echo "ERROR: Failed to stop ceremonyclient service"
    exit 1
fi

# Wait for the service to fully stop
echo "Waiting for service to stop completely..."
sleep 10

# Sync the store directory to Storj
echo "Starting rclone sync to Storj..."
if ! rclone sync $HOME/ceremonyclient/node/.config/store storj:/quilibrium/snapshot/store; then
    echo "ERROR: Failed to sync store directory to Storj"
    # Attempt to restart service before exiting
    systemctl start ceremonyclient
    exit 1
fi

# Wait for sync to complete and system to settle
echo "Waiting for sync to complete..."
sleep 10

# Restart the ceremony client service
echo "Restarting ceremonyclient service..."
if ! systemctl start ceremonyclient; then
    echo "ERROR: Failed to restart ceremonyclient service"
    exit 1
fi

echo "Sync completed and service restarted successfully"

#####################
# Logs - Cleanup
#####################

# Rotate logs
echo "Rotating logs..."
if ! tail -n $LOG_ENTRIES "$LOG_FILE" > "$LOG_FILE.tmp"; then
    echo "ERROR: Failed to rotate logs"
    exit 1
fi

if ! mv "$LOG_FILE.tmp" "$LOG_FILE"; then
    echo "ERROR: Failed to move rotated log file"
    exit 1
fi

echo "Script completed successfully"