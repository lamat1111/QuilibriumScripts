#!/bin/bash

# Function to check if running with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi
}

# Function to download and execute the latest script
download_update_script() {
    mkdir -p ${HOME}/scripts && \
    curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qnode_service_update.sh" -o ${HOME}/scripts/qnode_service_update.sh && \
    chmod +x ${HOME}/scripts/qnode_service_update.sh
}

# Function to create service file
create_service_file() {
    # Store the current user's home directory
    CURRENT_HOME=${HOME}
    
    cat << EOF > /etc/systemd/system/qnode-autoupdate.service
[Unit]
Description=QNode Service Update Script
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash ${CURRENT_HOME}/scripts/qnode_service_update.sh
User=$(id -un)
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
}

# Function to create timer file - once every 12 hrs
# create_timer_file() {
#     cat << EOF > /etc/systemd/system/qnode-autoupdate.timer
# [Unit]
# Description=Run QNode Service Update every 12 hours at a consistent time

# [Timer]
# OnBootSec=5min
# # Runs every 12 hours
# OnCalendar=*-*-* 0/12:00:00
# # One initial random delay up to 12 hours that becomes fixed
# RandomizedDelaySec=43200
# # This is key - makes the random delay consistent
# FixedRandomDelay=true
# # Persistent=true ensures the timing persists across reboots
# Persistent=true
# Unit=qnode-autoupdate.service

# [Install]
# WantedBy=timers.target
# EOF
# }

# Function to create timer file - once every 1 hr
create_timer_file() {
    cat << EOF > /etc/systemd/system/qnode-autoupdate.timer
[Unit]
Description=Run QNode Service Update every hour at a fixed minute

[Timer]
OnBootSec=5min
OnCalendar=hourly
RandomizedDelaySec=3600sec
FixedRandomDelay=true
Persistent=true
Unit=qnode-autoupdate.service

[Install]
WantedBy=timers.target
EOF
}

# Function to activate service and timer
activate_service_and_timer() {
    systemctl daemon-reload
    systemctl enable qnode-autoupdate.timer
    systemctl start qnode-autoupdate.timer
    echo "✅ Auto updates are ON."
}

# Main script logic
main() {
    check_sudo
    download_update_script

    if systemctl list-unit-files | grep -q qnode-autoupdate.service; then
        if systemctl is-active --quiet qnode-autoupdate.timer; then
            echo "QNode auto-update service and timer are already active."
            echo "✅ Auto updates are ON."
        else
            echo "QNode auto-update service and timer exist but are not active. Activating..."
            activate_service_and_timer
        fi
    else
        echo "Setting up QNode auto-update service and timer..."
        create_service_file
        create_timer_file
        activate_service_and_timer
    fi
}

main