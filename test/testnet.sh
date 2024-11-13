#!/bin/bash


SCRIPT_VERSION="1.3"

# Set the version number
NODE_VERSION="2.0.3-b9-testnet"
QCLIENT_VERSION="2.0.3"

# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/testnet"
EXEC_START="$NODE_PATH/node"
CONFIG_FILE="$HOME/testnet/.config/config.yml"

cat << EOF

                    Q1Q1Q1\    Q1\   
                   Q1  __Q1\ Q1Q1 |  
                   Q1 |  Q1 |\_Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1  Q1Q1 |  Q1 |  
                   \Q1Q1Q1 / Q1Q1Q1\ 
                    \___Q1Q\ \______|  QUILIBRIUM.ONE
                        \___|        
                              
===========================================================================
                 ✨ TESTNET NODE INSTALLER - $SCRIPT_VERSION ✨
===========================================================================
This script will install a testet Quilibrium node.
If you are running this ona machine hosting a mainnet node, 
you have to stop that one first.

The testnet node will be installed ina different folder,
and won't interfere with your mainnet node files.

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 3

# Check and stop ceremonyclient service if it exists
if systemctl list-units --full -all | grep -Fq "ceremonyclient.service"; then
    echo "⚠️ Detected existing ceremonyclient service"
    echo "⏳ Stopping ceremonyclient service..."
    sudo systemctl stop ceremonyclient.service
    sleep 2
    echo "✅ ceremonyclient service stopped"
else
    echo "ℹ️ No existing ceremonyclient service detected"
fi



# For DEBIAN OS - Check if sudo is installed
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
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    fi
fi

echo "⏳ Creating Testnet Directories: ~/testnet/node"
sleep 1
mkdir -p $HOME/testnet && cd ~/testnet

# Step 6: Create or Update Ceremonyclient Service
echo "⏳ Stopping Qtest Service if running"
sudo systemctl stop qtest.service 2>/dev/null || true
sleep 2

#==========================
# NODE BINARY DOWNLOAD
#==========================

# Step 4: Download qClient
echo "⏳Downloading qClient"
sleep 1
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

# Check if this is a cluster node by examining the existing service file
if [ -f "/lib/systemd/system/qtest.service" ]; then
    if grep -q "qnode_cluster_run_testnet.sh" "/lib/systemd/system/qtest.service"; then
        echo "⚠️ Detected cluster node configuration."
        echo "✅ Cluster nodes have different configurations. Your existing setup will be preserved."
        echo "⚠️ Please restart your cluster manually when ready."
        exit 0
    fi
fi

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

# Generate config.yml file
echo "⏳ Generating .config/config.yml file"
./node --signature-check=false -peer-id
sleep 5


echo "⏳ Editing config.yml file"
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

# Update GRPC and REST multiaddr settings
if grep -q '^listenGrpcMultiaddr: ""' "$CONFIG_FILE" || grep -q '^listenRESTMultiaddr: ""' "$CONFIG_FILE"; then
    # Update the multiaddr settings
    sed -i 's|^listenGrpcMultiaddr: ""|listenGrpcMultiaddr: "/ip4/127.0.0.1/tcp/8337"|' "$CONFIG_FILE"
    sed -i 's|^listenRESTMultiaddr: ""|listenRESTMultiaddr: "/ip4/127.0.0.1/tcp/8338"|' "$CONFIG_FILE"
    echo "Updated GRPC and REST multiaddr settings"
else
    echo "GRPC and REST multiaddr settings already configured, skipping"
fi

# Restart service only if config was changed
if [ $? -eq 0 ]; then
    echo "Restarting service with new configuration"
    sudo systemctl restart qtest.service
fi

echo
echo "Important info:"
echo "------------------------------------------------------------"
echo "Installation folder:  $NODE_PATH"
echo "Current node version: $NODE_VERSION \\(renamed as simply 'node'\\)"
echo
echo "service name:  qtest"
echo "Start service: service qtest start"
echo "Stop service:  service qtest stop"
echo "node log:      journalctl -u qtest.service -f --no-hostname -o cat"
echo "-------------------------------------------------------------"
sleep 3
echo
echo "Showing node logs:"
sudo journalctl -u qtest.service -f --no-hostname -o cat