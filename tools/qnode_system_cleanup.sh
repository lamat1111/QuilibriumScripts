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

Processing... ⏳

EOF
}

# Function to show progress
show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        printf "\b\b\b\b"
        sleep $delay
    done
    printf "    \b\b\b\b"
}

# Function to calculate freed space
calculate_freed_space() {
    local before=$1
    local after=$2
    echo "scale=2; $before - $after" | bc
}

# Backup function for important logs before cleaning
backup_important_logs() {
    local backup_dir="/var/log/cleaned_logs_backup"
    local date_stamp=$(date +%Y%m%d_%H%M%S)
    
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

    # APT cleanup
    sudo apt-get clean >/dev/null 2>&1
    sudo apt-get autoclean >/dev/null 2>&1
    sudo apt-get autoremove --purge -y >/dev/null 2>&1

    # Remove old kernels (keeping the current and one previous version)
    sudo dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | grep -v $(uname -r) | head -n -1 | xargs sudo apt-get -y purge >/dev/null 2>&1

    # Clean package manager cache
    sudo rm -rf /var/cache/apt/archives/* >/dev/null 2>&1
    sudo rm -rf /var/cache/apt/archives/partial/* >/dev/null 2>&1

    # Clean temporary files
    sudo rm -rf /tmp/* >/dev/null 2>&1
    sudo rm -rf /var/tmp/* >/dev/null 2>&1

    # Clean old logs (keeping last 7 days)
    sudo find /var/log -type f -name "*.log" -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    sudo find /var/log -type f -name "*.log.*" -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    
    # Clean and optimize systemd journal
    sudo journalctl --rotate >/dev/null 2>&1
    sudo journalctl --vacuum-time=7d >/dev/null 2>&1
    
    # Clean old systemd journal files
    sudo rm -f /var/log/journal/*/*.journal~ >/dev/null 2>&1

    # Clean old audit logs if they exist
    if [ -d "/var/log/audit" ]; then
        sudo find /var/log/audit -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    fi

    # Clean crash reports
    sudo rm -rf /var/crash/* >/dev/null 2>&1

    # Clean up failed systemd units
    sudo systemctl reset-failed >/dev/null 2>&1

    # Clean Docker if installed (with extra safety checks)
    if command -v docker >/dev/null; then
        # Remove unused containers, networks, and dangling images
        docker system prune -f >/dev/null 2>&1
        
        # Remove unused volumes (be careful with this one)
        # docker volume prune -f >/dev/null 2>&1  # Commented out for safety
    fi

    # Clean old sessions
    sudo rm -rf /var/lib/systemd/sessions/* >/dev/null 2>&1

    # Clean obsolete alternatives
    sudo update-alternatives --remove-all ls >/dev/null 2>&1

    # Clean Linux Server Performance logs
    sudo rm -rf /var/log/sa/* >/dev/null 2>&1

    # Clean old wtmp and btmp logs (login records)
    sudo truncate -s 0 /var/log/wtmp >/dev/null 2>&1
    sudo truncate -s 0 /var/log/btmp >/dev/null 2>&1

    # Clean old mail logs if they exist
    if [ -d "/var/log/mail" ]; then
        sudo find /var/log/mail -type f -mtime +7 -exec rm -f {} \; >/dev/null 2>&1
    fi
}

# Main function
main() {
    # show banner
    show_banner
    
    # Get initial sizes
    initial_size=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')

    # Run cleanup in background and show progress
    clean_system &
    show_progress $!

    # Get final sizes
    final_size=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    
    # Calculate freed space
    freed_space=$(calculate_freed_space $final_size $initial_size)

    # Show completion message
    echo
    echo -e "\n✅ Cleanup completed successfully!"
    echo -e "Freed approximately ${freed_space}GB of space"
}

# Execute main function
main