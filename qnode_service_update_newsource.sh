#!/bin/bash

# Step 0: Welcome
echo "This script will update your Qnode. The node must be running as a service."
echo "Made with ❤️ by 0xOzgur.eth (edited by LaMat)"
echo "Processing..."
sleep 7  # Add a 7-second delay

# Step 1: Stop the ceremonyclient service
echo "Step 1: Stopping the ceremonyclient service..."
if service ceremonyclient stop; then
    echo "Service stopped successfully."
else
    echo "Error stopping the ceremonyclient service." >&2
    exit 1
fi
sleep 1

# Step 2: Download Binary
echo "Step 2: ⏳ Downloading New Release"

# Change to the ceremonyclient directory
cd ~/ceremonyclient || { echo "Error: Directory ~/ceremonyclient does not exist."; exit 1; }

# Set the remote URL
git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git || { echo "❌ Error: Failed to set remote URL." >&2; exit 1; }

# Pull the latest changes
git pull || { echo "❌ Error: Failed to download the latest changes." >&2; exit 1; }

echo "✅ Downloaded the latest changes successfully."

# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Step 3:Re-Create Ceremonyclient Service
echo "⏳ Re-Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay
rm /lib/systemd/system/ceremonyclient.service
sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF


# Step 5: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Showing the node logs
echo "🌟Your Qnode is now updated to 1.4.18"
echo "⏳ I will now show the node log (CTRL+C to detatch from the log flow)"
echo ""
echo ""
sleep 3  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
