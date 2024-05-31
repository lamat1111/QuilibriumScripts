#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will update your Quilibrium node if you are running it as a service. ✨"
echo "This script is tailored for Ubuntu machines. Please verify compatibility if using another OS."
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Stop the ceremonyclient service
echo "🛑 Halting Ceremonyclient Service..."
if ! sudo service ceremonyclient stop; then
    echo "❌ Error: Unable to stop ceremonyclient service." >&2
    exit 1
fi

# Step 1: Download Binary
echo "⬇️ Fetching New Release..."
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient not found."; exit 1; }
if ! git pull && ! git checkout release; then
    echo "❌ Error: Failed to download and checkout release branch." >&2
    exit 1
fi

# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Step 3: Re-Create or Update Ceremonyclient Service
echo "🔧 Rebuilding Ceremonyclient Service..."
sleep 2  # Add a 2-second delay
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "📝 Creating new ceremonyclient service file..."
    if ! sudo tee "$SERVICE_FILE" > /dev/null <<EOF
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
    then
        echo "❌ Error: Failed to create ceremonyclient service file." >&2
        exit 1
    fi
else
    echo "🔍 Checking existing ceremonyclient service file..."
    # Check if the required lines exist and if they are different
    if ! grep -q "WorkingDirectory=$NODE_PATH" "$SERVICE_FILE" || ! grep -q "ExecStart=$EXEC_START" "$SERVICE_FILE"; then
        echo "🔄 Updating existing ceremonyclient service file..."
        # Replace the existing lines with new values
        sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=$NODE_PATH|" "$SERVICE_FILE"
        sudo sed -i "s|ExecStart=.*|ExecStart=$EXEC_START|" "$SERVICE_FILE"
    else
        echo "✅ No changes needed."
    fi
fi

# Step 4: Start the ceremonyclient service
echo "🚀 Initiating Ceremonyclient Service..."
sleep 2  # Add a 2-second delay
if ! sudo systemctl daemon-reload && ! sudo systemctl enable ceremonyclient && ! sudo service ceremonyclient start; then
    echo "❌ Error: Failed to start ceremonyclient service." >&2
    exit 1
fi

# See the logs of the ceremonyclient service
echo "🎉 Your Quilibrium node is updated!"
echo "I will now show th e ode logs. Press CTRL + C to exit."
echo ""
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
