#!/bin/bash
SERVICE_FILE=/lib/systemd/system/ceremonyclient.service
CPU_LIMIT_PERCENT=85

echo "✨ Welcome! ✨"
echo "✨ This script will disable HT (HyperThreading) and set a new CPUQuota limit of $CPU_LIMIT_PERCEN%"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Function to print messages with emojis
print_message() {
    echo -e "\n$1 $2\n"
}

# Function to handle errors
error_handler() {
    print_message "❌" "An error occurred. Exiting the script."
    exit 1
}

# Adding trap for error handling
trap 'error_handler' ERR

print_message "🚀" "Starting the script. Please follow along..."
sleep 2

# ==================
# Open the GRUB Configuration File
# ==================
print_message "📝" "Opening the GRUB configuration file..."
sleep 2

sudo nano /etc/default/grub || error_handler

# ==================
# Edit the GRUB_CMDLINE_LINUX Line
# ==================
print_message "🛠️" "Editing the GRUB_CMDLINE_LINUX line..."
sleep 2

# Ensure the grub configuration file is updated
sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX="[^"]*)(.*)(")$/\1\2 nosmt\3/' /etc/default/grub || error_handler

# ==================
# Save the File
# ==================
print_message "💾" "Saving the GRUB configuration file..."
sleep 2

# ==================
# Update GRUB
# ==================
print_message "🔄" "Updating GRUB with the new configuration..."
sleep 2

sudo update-grub || error_handler

# ==================
# Update the CPUQuota Limit in the Service File
# ==================
print_message "📊" "Calculating the new CPUQuota limit..."
sleep 2

VCores=$(nproc)
NewCPUQuota=$((VCores * CPU_LIMIT_PERCENT))

print_message "📝" "Updating the service file with the new CPUQuota limit..."
sleep 2

if grep -q "CPUQuota=" $SERVICE_FILE; then
    sudo sed -i -E "s/CPUQuota=[0-9]+%/CPUQuota=${NewCPUQuota}%/" $SERVICE_FILE || error_handler
else
    sudo sed -i '/\[Service\]/a CPUQuota='${NewCPUQuota}'%' $SERVICE_FILE || error_handler
fi

# ==================
# Reload Service Systemd
# ==================
print_message "🔄" "Reloading systemd to apply changes..."
sleep 2

sudo systemctl daemon-reload || error_handler

# ==================
# Reboot the System
# ==================
print_message "🔄" "Rebooting the system to apply changes..."
sleep 2

sudo reboot || error_handler
