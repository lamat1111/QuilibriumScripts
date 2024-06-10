#!/bin/bash

cat << "EOF"

                      QQQQQQQQQ       1111111   
                    QQ:::::::::QQ    1::::::1   
                  QQ:::::::::::::QQ 1:::::::1   
                 Q:::::::QQQ:::::::Q111:::::1   
                 Q::::::O   Q::::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O  QQQQ:::::Q   1::::l   
                 Q::::::O Q::::::::Q   1::::l   
                 Q:::::::QQ::::::::Q111::::::111
                  QQ::::::::::::::Q 1::::::::::1
                    QQ:::::::::::Q  1::::::::::1
                      QQQQQQQQ::::QQ111111111111
                              Q:::::Q           
                               QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


==========================================================================
                         ✨ SYSTEM CLEANER ✨
==========================================================================
This script will clean up your system 
from temporary files and old log entries


Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 7

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

# Main function
main() {
    echo "Starting system cleanup..."

    # Capture initial disk space
    echo "Initial free disk space: $(capture_disk_space)"
    echo ""

    # Vacuum journal logs
    vacuum_journal_logs

    # Clean system caches and temporary files
    clean_system

    # Capture final disk space
    echo ""
    echo "Final free disk space: $(capture_disk_space)"
    echo ""

    echo "🌟 Cleanup process completed successfully."
}

# Call the main function
main
