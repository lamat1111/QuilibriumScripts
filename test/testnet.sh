#!/bin/bash
# Set the version number

VERSION="2.0.3-b6-testnet"
qClientVERSION="2.0.2.4"

cd ~
# Step 0: Welcome"
echo "The script is prepared for Ubuntu machines. If you are using another operating system, please check the compatibility of the script."
echo "This script will be building new fresh Node for Quilibrium Testnet. Your use is at your own risk. 0xOzgur does not accept any liability."
echo "⏳Enjoy and sit back while you are building your Quilibrium Testnet Node!"
echo "⏳Processing..."
sleep 5

# For DEBIAN OS - Check if sudo and git is installed
if ! command -v sudo &> /dev/null; then
    echo "sudo could not be found"
    echo "Installing sudo..."
    su -c "apt update && apt install sudo -y"
else
    echo "sudo is installed"
fi

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-amd64"
        QCLIENT_BINARY="qclient-$qClientVERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-amd64"
        QCLIENT_BINARY="qclient-$qClientVERSION-darwin-arm64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-arm64"
        QCLIENT_BINARY="qclient-$qClientVERSION-linux-arm64"
    fi
fi

echo "⏳ Creating Testnet Directories"
sleep 1
mkdir -p ~/qtestnet/node

#==========================
# NODE BINARY DOWNLOAD
#==========================

# Step 4: Download qClient
echo "⏳Downloading qClient"
sleep 1
cd ~/qtestnet/node

# Always download and overwrite
wget -O $NODE_BINARY https://releases.quilibrium.com/$NODE_BINARY
chmod +x $NODE_BINARY
rm -f ./node
echo "removed node old version"
cp -p ./$NODE_BINARY ./node
echo "copied $NODE_BINARY to node"
echo "✅ Node binary for testnet downloaded and permissions configured completed."

#==========================
# qCLIENT BINARY DOWNLOAD
#==========================
# Always download and overwrite
wget -O $QCLIENT_BINARY https://releases.quilibrium.com/$QCLIENT_BINARY
chmod +x $QCLIENT_BINARY
rm -f ./qclient
echo "removed qclient old version"
cp -p ./$QCLIENT_BINARY ./qclient
echo "copied $QCLIENT_BINARY to qclient"
echo "✅ qClient binary for testnet downloaded and permissions configured completed."
echo

# Step 5: Determine the ExecStart line based on the architecture
# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/qtestnet/node"
EXEC_START="$NODE_PATH/node"

# Step 6: Create or Update Ceremonyclient Service
echo "⏳ Stopping Ceremonyclient Service if running"
sudo systemctl stop qtest.service 2>/dev/null || true
sleep 2

echo "⏳ Creating/Updating Ceremonyclient Testnet Service"
sleep 2

# Create a temporary service file
TMP_SERVICE_FILE=$(mktemp)
cat > "$TMP_SERVICE_FILE" <<EOF
[Unit]
Description=Ceremony Client Testnet Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START --signature-check=false --network=1
KillSignal=SIGINT
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF

# Compare with existing service file and only update if different
if ! cmp -s "$TMP_SERVICE_FILE" "/lib/systemd/system/qtest.service" 2>/dev/null; then
    sudo mv "$TMP_SERVICE_FILE" "/lib/systemd/system/qtest.service"
    sudo systemctl daemon-reload
    echo "Service file updated"
else
    rm "$TMP_SERVICE_FILE"
    echo "Service file unchanged"
fi

# Step 7: Start the ceremonyclient service
echo "✅Starting Ceremonyclient Testnet Service"
sleep 1
sudo systemctl start qtest.service

# Step 8: Wait for config file generation and update
echo "🎉Welcome to Quilibrium testnet node $VERSION"
echo "⏳ Waiting for config.yml file generation (30 seconds)"
sleep 30

CONFIG_FILE="$HOME/qtestnet/node/.config/config.yml"

# Wait for config file to exist
for i in {1..30}; do
    if [ -f "$CONFIG_FILE" ]; then
        break
    fi
    echo "Waiting for config file to be generated... (attempt $i/30)"
    sleep 2
done

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file was not generated within the timeout period"
    exit 1
fi

echo "⏳ Editing config.yml file"

# Backup the original file if it hasn't been backed up yet
if [ ! -f "${CONFIG_FILE}.bak" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Update bootstrap peers only if they haven't been updated
if ! grep -q "91.242.214.79" "$CONFIG_FILE"; then
    # Comment out existing bootstrap peers
    sed -i '/bootstrapPeers:/,/^[^ ]/s/^  -/#  -/' "$CONFIG_FILE"
    # Add the new bootstrap peer if it's not already there
    sed -i '/bootstrapPeers:/a\  - /ip4/91.242.214.79/udp/8336/quic-v1/p2p/QmNSGavG2DfJwGpHmzKjVmTD6CVSyJsUFTXsW4JXt2eySR' "$CONFIG_FILE"
    echo "Bootstrap peers updated in $CONFIG_FILE"
else
    echo "Bootstrap peers already updated, skipping"
fi

# Restart service only if config was changed
if [ $? -eq 0 ]; then
    echo "Restarting service with new configuration"
    sudo systemctl restart qtest.service
fi

echo "Setup complete. Showing logs:"
sudo journalctl -u qtest.service -f --no-hostname -o cat