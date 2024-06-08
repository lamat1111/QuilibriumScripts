#!/bin/bash


# Step 0: Welcome
echo "✨ Welcome! This script will update your Quilibrium node when running it as a service. ✨"
echo "It will run the node directly form the binary"
echo "It will update your service file without changing your customizations"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

#===========================
# Set variables
#===========================

# Set service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
# User working folder
HOME=$(eval echo ~$USER)
# Node path
NODE_PATH="$HOME/ceremonyclient/node"

#===========================
# Check if ceremonyclient directory exists
#===========================
HOME=$(eval echo ~$USER)
CEREMONYCLIENT_DIR="$HOME/ceremonyclient"

if [ ! -d "$CEREMONYCLIENT_DIR" ]; then
    echo "❌ Error: You don't have a node installed yet. Nothing to update. Exiting..."
    exit 1
fi

#===========================
# Stop the ceremonyclient service if it exists
#===========================
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl is-active --quiet ceremonyclient; then
    if sudo systemctl stop ceremonyclient; then
        echo "🔴 Service stop command issued."
    else
        echo "❌ Failed to issue stop command for ceremonyclient service." >&2
    fi

    sleep 1

    # Verify the service has stopped
    if systemctl is-active --quiet ceremonyclient; then
        echo "⚠️ Service is still running. Attempting to stop it forcefully..."
        if sudo systemctl kill ceremonyclient; then
            sleep 1
            if systemctl is-active --quiet ceremonyclient; then
                echo "❌ Service could not be stopped forcefully." >&2
            else
                echo "✅ Service stopped forcefully."
            fi
        else
            echo "❌ Failed to force stop the ceremonyclient service." >&2
        fi
    else
        echo "✅ Service stopped successfully."
    fi
else
    echo "ℹ️ Ceremonyclient service is not running or does not exist."
fi

sleep 1

#===========================
# Move to the ceremonyclient directory
#===========================
echo "Moving to the ceremonyclient directory..."
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient does not exist."; exit 1; }

#===========================
# Discard local changes in release_autorun.sh
#===========================
echo "✅ Discarding local changes in release_autorun.sh..."
git checkout -- node/release_autorun.sh

#===========================
# Download Binary
#===========================
echo "⏳ Downloading New Release..."


# Download new release
echo "⏳ Downloading New Release v1.4.19"
cd  ~/ceremonyclient
git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git || git remote set-url origin https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git
git pull
git checkout release-cdn

echo "✅ Downloaded the latest changes successfully."

sleep 1
#===========================
# Determine the ExecStart line based on the architecture
#===========================
# Set the version number
VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Get the system architecture
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

sleep 1

#===========================
# Re-Create or Update Ceremonyclient Service
#===========================
echo "🔧 Checking Ceremonyclient Service..."
sleep 2  # Add a 2-second delay

if [ ! -f "$SERVICE_FILE" ]; then
    echo "📝 Service file does not exist. Creating new ceremonyclient service file..."
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

    # Replace the existing lines with new values
    if sudo grep -q "WorkingDirectory=" "$SERVICE_FILE"; then
        sudo sed -i "s|^WorkingDirectory=.*|WorkingDirectory=$NODE_PATH|" "$SERVICE_FILE"
    else
        echo "WorkingDirectory not found in the service file. Adding it."
        sudo sed -i "/\[Service\]/a WorkingDirectory=$NODE_PATH" "$SERVICE_FILE"
    fi

    if sudo grep -q "ExecStart=" "$SERVICE_FILE"; then
        sudo sed -i "s|^ExecStart=.*|ExecStart=$EXEC_START|" "$SERVICE_FILE"
    else
        echo "ExecStart not found in the service file. Adding it."
        sudo sed -i "/\[Service\]/a ExecStart=$EXEC_START" "$SERVICE_FILE"
    fi

    echo "✅ Ceremonyclient service file updated."
fi  

sleep 1  # Add a 1-second delay

#===========================
# Remove the SELF_TEST file
#===========================
if [ -f "$NODE_PATH/.config/SELF_TEST" ]; then
    echo "🗑️ Removing SELF_TEST file..."
    if rm "$NODE_PATH/.config/SELF_TEST"; then
        echo "✅ SELF_TEST file removed successfully."
    else
        echo "❌ Error: Failed to remove SELF_TEST file." >&2
        exit 1
    fi
else
    echo "ℹ️ No SELF_TEST file found at $NODE_PATH/.config/SELF_TEST."
fi
sleep 1  # Add a 1-second delay

#===========================
# Start the ceremonyclient service
#===========================
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

#===========================
# Showing the node logs
#===========================
echo ""
echo "🌟Your Qnode is now updated to $VERSION!"
echo ""
echo "⏳ Showing the node log... (Hit Ctrl+C to exit log)"
sleep 1
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
