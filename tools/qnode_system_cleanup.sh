#!/bin/bash

# Function to display the banner
show_banner() {
    cat << "EOF"

                    Q1Q1Q1\    Q1\   
                   Q1  __Q1\ Q1Q1 |  
                   Q1 |  Q1 |\_Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1  Q1Q1 |  Q1 |  
                   \Q1Q1Q1 / Q1Q1Q1\ 
                    \___Q1Q\ \______|  QUILIBRIUM.ONE
                        \___|        
                              
==========================================================================
                         ✨ SYSTEM CLEANER ✨
==========================================================================
This script will clean up your system from temp files and old logs


Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

EOF
}

# Function to show status message
show_status() {
    echo "Cleaning: $1..."
}

# Function to calculate freed space in MB
calculate_freed_space() {
    local before=$1
    local after=$2
    echo "scale=2; ($before - $after) * 1024" | bc
}

# Backup function for important logs before cleaning
backup_important_logs() {
    local backup_dir="/var/log/cleaned_logs_backup"
    local date_stamp=$(date +%Y%m%d_%H%M%S)
    
    show_status "Important system logs"
    
    # Create backup directory if it doesn't exist
    sudo mkdir -p "$backup_dir"
    
    # Backup authentication logs
    if [ -f "/var/log/auth.log" ]; then
        sudo cp /var/log/auth.log "$backup_dir/auth.log.$date_stamp"
    fi
    
    # Backup system logs
    if [ -f "/var/log/syslog" ]; then
        sudo cp /var/log/syslog "$backup_dir/syslog.$date_stamp"
    fi
    
    # Keep only last 5 backups
    cd "$backup_dir" && ls -t | tail -n +6 | xargs -r sudo rm --
}

# Function for safe system cleanup
clean_system() {
    # Backup important logs first
    backup_important_logs

    show_status "APT cache"
    sudo apt-get clean >/dev/null 2>&1
    sudo apt-get autoclean >/dev/null 2>&1
    sudo apt-get autoremove --purge -y >/dev/null 2>&1

    show_status "Old kernels"
    sudo dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | grep -v $(uname -r) | head -n -1 | xargs sudo apt-get -y purge >/dev/null 2>&1

    show_status "Package manager cache"
    sudo rm -rf /var/cache/apt/archives/* >/dev/null 2>&1
    sudo rm -rf /var/cache/apt/archives/partial/* >/dev/null 2>&1

    show_status "Temporary files"
    sudo rm -rf /tmp/* >/dev/null 2>&1
    sudo rm -rf /var/tmp/* >/dev/null 2>&1

    show_status "Old log files"
    sudo find /var/log -type f -name "*.log" -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    sudo find /var/log -type f -name "*.log.*" -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    
    show_status "Systemd journal"
    sudo journalctl --rotate >/dev/null 2>&1
    sudo journalctl --vacuum-time=7d >/dev/null 2>&1
    sudo rm -f /var/log/journal/*/*.journal~ >/dev/null 2>&1

    if [ -d "/var/log/audit" ]; then
        show_status "Audit logs"
        sudo find /var/log/audit -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    fi

    show_status "Crash reports"
    sudo rm -rf /var/crash/* >/dev/null 2>&1

    show_status "Failed systemd units"
    sudo systemctl reset-failed >/dev/null 2>&1

    if command -v docker >/dev/null; then
        show_status "Docker system"
        docker system prune -f >/dev/null 2>&1
    fi

    show_status "Old sessions"
    sudo rm -rf /var/lib/systemd/sessions/* >/dev/null 2>&1

    show_status "Obsolete alternatives"
    sudo update-alternatives --remove-all ls >/dev/null 2>&1

    show_status "Performance logs"
    sudo rm -rf /var/log/sa/* >/dev/null 2>&1

    show_status "Login records"
    sudo truncate -s 0 /var/log/wtmp >/dev/null 2>&1
    sudo truncate -s 0 /var/log/btmp >/dev/null 2>&1

    if [ -d "/var/log/mail" ]; then
        show_status "Mail logs"
        sudo find /var/log/mail -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    fi
}

# Main function
main() {
    # Show banner
    show_banner
    
    echo "Starting cleanup..."
    echo
    
    # Get initial sizes
    initial_size=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')

    # Run cleanup
    clean_system

    # Get final sizes
    final_size=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    
    # Calculate freed space
    freed_space=$(calculate_freed_space $initial_size $final_size)

    # Show completion message
    echo
    echo "✅ Cleanup completed successfully!"
    echo "💾 Freed approximately ${freed_space}MB of space"
}

# Execute main function
main