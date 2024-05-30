#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will prepare your server for the Quilibrium node installation. ✨"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "Helped by 0xOzgur.eth - https://quilibrium.space"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Exit on any error
set -e

# Step 1: Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "🔄 You can try to run the script from scratch again."
    echo "🛠️ If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}

# Step 2: Set a trap to call exit_message on any error
trap exit_message ERR

# Step 4: Download Ceremonyclient
echo "⏳Downloading Ceremonyclient"
sleep 1  # Add a 1-second delay
cd ~
if [ -d "ceremonyclient" ]; then
  echo "Directory ceremonyclient already exists, skipping git clone..."
else
  until git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git; do
    echo "Git clone failed, retrying..."
    sleep 2
  done
fi
cd ~/ceremonyclient/
git checkout release

# Step 4.1: Build Ceremonyclient qClient
echo "⏳ Building qCiient..."
sleep 1  # Add a 1-second delay
cd ~/ceremonyclient/client
GOEXPERIMENT=arenas go build -o qclient main.go

# Step 5:Determine the ExecStart line based on the architecture
# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)
# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Create Ceremonyclient Service
echo "⏳Creating Ceremonyclient Service"
sleep 1  # Add a 1-second delay
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

# Step 7: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"

sleep 2  # Add a 2-second delay
sudo systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Step 8: Final messages
echo "🎉 Now your node is starting!"
echo "🕒 Let it run for at least 30 minutes to generate your keys."
echo ""
echo "🔐 You can logout of your server if you want and login again later."
echo "🔒 After 30 minutes, backup your keys.yml and config.yml files."
echo "ℹ️ More info about this in the online guide: https://docs.quilibrium.one"
echo ""
echo "📜 Now I will show the node log below..."
echo "To exit the log, just type CTRL +C."

# Step 9: See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
