#!/bin/bash

echo "==========================================================================="
echo "                       🔄 QNODE SERVER REVERT 🔄"
echo "==========================================================================="
echo "This script will revert changes made by the QNode server setup script."
echo "Please run this script with sudo privileges."
echo "==========================================================================="

# Function to remove a line from a file if it exists
remove_line_from_file() {
    if grep -q "$1" "$2"; then
        sudo sed -i "\|$1|d" "$2"
        echo "✅ Removed '$1' from $2."
    else
        echo "✅ '$1' not found in $2. No action needed."
    fi
}

# Uninstall packages
echo "⏳ Uninstalling packages..."
sudo apt-get remove -y git tar tmux cron jq grpcurl ufw fail2ban

# Remove Go
echo "⏳ Removing Go..."
sudo rm -rf /usr/local/go
remove_line_from_file 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc
remove_line_from_file "export GOPATH=$HOME/go" ~/.bashrc
remove_line_from_file "export GO111MODULE=on" ~/.bashrc
remove_line_from_file "export GOPROXY=https://goproxy.cn,direct" ~/.bashrc

# Remove gRPCurl
echo "⏳ Removing gRPCurl..."
sudo rm -f $(which grpcurl)

# Revert network buffer sizes
echo "⏳ Reverting network buffer sizes..."
sudo sed -i '/net.core.rmem_max=600000000/d' /etc/sysctl.conf
sudo sed -i '/net.core.wmem_max=600000000/d' /etc/sysctl.conf
sudo sysctl -p

# Remove UFW rules
echo "⏳ Removing UFW rules..."
sudo ufw --force reset

# Remove Fail2Ban
echo "⏳ Removing Fail2Ban..."
sudo apt-get remove -y fail2ban
sudo rm -rf /etc/fail2ban

# Remove created folders
echo "⏳ Removing created folders..."
#sudo rm -rf /root/backup/
#sudo rm -rf /root/scripts/

# Clean up package manager
echo "⏳ Cleaning up package manager..."
sudo apt-get autoremove -y
sudo apt-get clean

echo "🎉 Revert process completed!"
echo "You may want to reboot your server to ensure all changes take effect."
echo "Type 'sudo reboot' and press ENTER to reboot your server."