#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will clean up your system from temporary files and old log entries ✨"
echo "It will stop/start the Quilibrium node service as well."
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Function to print a separator line
print_separator() {
    echo "======================================================================"
}

# Function to capture disk space
capture_disk_space() {
    df -h / | grep '/' | awk '{print $4}'
}

# Function to vacuum journal logs
vacuum_journal_logs() {
    echo "Vacuuming journalctl logs..."
    sudo journalctl --vacuum-size=500M
    print_separator
}

# Function to clean system caches and temporary files
clean_system() {
    echo "Cleaning system caches and temporary files..."
    sudo apt-get clean
    sudo apt-get autoclean  # Remove obsolete deb-packages
    sudo rm -rf /var/cache/apt/archives
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*
    sudo rm -rf ~/.cache/*
    echo "System cleanup complete."
    print_separator
}

# Function to stop ceremonyclient service
stop_ceremonyclient_service() {
    echo "Stopping ceremonyclient service..."
    sudo service ceremonyclient stop
    echo "Ceremonyclient service stopped."
    print_separator
}

# Function to start ceremonyclient service
start_ceremonyclient_service() {
    echo "Starting ceremonyclient service..."
    sudo service ceremonyclient start
    echo "Ceremonyclient service started."
    print_separator
}

# Main function
main() {
    echo "Starting system cleanup..."

    # Stop ceremonyclient service
    stop_ceremonyclient_service

    # Capture initial disk space
    echo "Initial free disk space: $(capture_disk_space)"

    # Vacuum journal logs
    vacuum_journal_logs

    # Clean system caches and temporary files
    clean_system

    # Capture final disk space
    echo "Final free disk space: $(capture_disk_space)"

    # Start ceremonyclient service
    start_ceremonyclient_service

    echo "🌟 Cleanup process completed successfully."
}

# Call the main function
main
