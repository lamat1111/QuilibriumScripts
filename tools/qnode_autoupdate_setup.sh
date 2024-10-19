#!/bin/bash

# Function to check if running with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi
}

# Function to download and execute the latest script
download_and_execute_script() {
    mkdir -p ~/scripts && \
    curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qnode_service_update.sh" -o ~/scripts/qnode_service_update.sh && \
    chmod +x ~/scripts/qnode_service_update.sh && \
    ~/scripts/qnode_service_update.sh
}

# Function to create service file
create_service_file() {
    cat << EOF > /etc/systemd/system/qnode-update.service
[Unit]
Description=QNode Service Update Script
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $HOME/scripts/qnode_service_update.sh
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF
}

# Function to create timer file
create_timer_file() {
    cat << EOF > /etc/systemd/system/qnode-update.timer
[Unit]
Description=Run QNode Service Update every hour at a consistent random minute

[Timer]
OnBootSec=5min
OnCalendar=hourly
RandomizedDelaySec=3000
FixedRandomDelay=true
Unit=qnode-update.service

[Install]
WantedBy=timers.target
EOF
}

# Function to activate service and timer
activate_service_and_timer() {
    systemctl reload qnode-update.service qnode-update.timer
    systemctl enable qnode-update.timer
    systemctl start qnode-update.timer
    echo "✅ Auto updates are ON."
}

# Main script logic
main() {
    check_sudo
    download_and_execute_script

    if systemctl list-unit-files | grep -q qnode-update.service; then
        if systemctl is-active --quiet qnode-update.timer; then
            echo "QNode update service and timer are already active."
            echo "✅ Auto updates are ON."
            exit 0
        else
            echo "QNode update service and timer exist but are not active. Activating..."
            activate_service_and_timer
            exit 0
        fi
    else
        echo "Setting up QNode update service and timer..."
        create_service_file
        create_timer_file
        activate_service_and_timer
        echo "Setup completed successfully."
        echo "✅ Auto updates are ON."
    fi
}

main