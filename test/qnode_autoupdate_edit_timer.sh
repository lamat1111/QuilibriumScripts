#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Create the new timer configuration
cat > /etc/systemd/system/qnode-autoupdate.timer << 'EOF'
[Unit]
Description=Run QNode Service Update every hour at a consistent random minute

[Timer]
OnBootSec=5min
OnCalendar=hourly
RandomizedDelaySec=3600
Persistent=true
Unit=qnode-autoupdate.service

[Install]
WantedBy=timers.target
EOF

# Check if the file was written successfully
if [ $? -ne 0 ]; then
    echo "Failed to write timer configuration"
    exit 1
fi

# Reload systemd daemon
systemctl daemon-reload
if [ $? -ne 0 ]; then
    echo "Failed to reload systemd daemon"
    exit 1
fi

# Restart the timer
systemctl enable qnode-autoupdate.timer
systemctl restart qnode-autoupdate.timer
if [ $? -ne 0 ]; then
    echo "Failed to restart timer"
    exit 1
fi

# Verify the timer is running
if systemctl is-active --quiet qnode-autoupdate.timer; then
    echo "Timer successfully updated and running"
    echo "Next trigger times:"
    systemctl list-timers qnode-autoupdate.timer
else
    echo "Timer is not running. Please check the configuration"
    exit 1
fi