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
sleep 5  # Add a 10-second delay

# Step 1: Update and Upgrade the Machine
echo "Updating the machine"
echo "⏳Processing..."
sleep 2  # Add a 2-second delay

# Fof DEBIAN OS - Check if sudo and git is installed
if ! command -v sudo &> /dev/null
then
    echo "sudo could not be found"
    echo "Installing sudo..."
    su -c "apt update && apt install sudo -y"
else
    echo "sudo is installed"
fi

if ! command -v git &> /dev/null
then
    echo "git could not be found"
    echo "Installing git..."
    su -c "apt update && apt install git -y"
else
    echo "git is installed"
fi

echo "⏳ Creating Testnet Directories"
sleep 1  # Add a 1-second delay
mkdir -p ~/testnet/ceremonyclient/{node,client}

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-amd64"
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
        QCLIENT_BINARY="qclient-$qClientVERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-amd64"
        GO_BINARY="go1.22.44.linux-amd64.tar.gz"
        QCLIENT_BINARY="qclient-$qClientVERSION-darwin-arm64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-arm64"
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-arm64"
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
        QCLIENT_BINARY="qclient-$qClientVERSION-linux-arm64"
    fi
fi


#==========================
# NODE BINARY DOWNLOAD
#==========================

# Step 4:Download qClient
echo "⏳Downloading qClient"
sleep 1  # Add a 1-second delay
    cd ~/testnet/ceremonyclient/node
    wget https://releases.quilibrium.com/$NODE_BINARY
    chmod +x $NODE_BINARY
    rm -f ./node
    echo removed node old version
    cp -p ./$NODE_BINARY-linux-amd64 ./node
    echo "renamed $NODE_BINARY-testnet-linux-amd64 to node"
echo "✅  Node binary for testnet downloaded and permissions configured completed."

#==========================
# qCLIENT BINARY DOWNLOAD
#==========================
    wget https://releases.quilibrium.com/$QCLIENT_BINARY
    chmod +x $QCLIENT_BINARY
    rm -f ./qclient
    echo "removed qclient old version"
    cp -p ./$QCLIENT_BINARY-linux-amd64 ./qclient
    echo "renamed $QCLIENT_BINARY-testnet-linux-amd64 to qclient"
echo "✅  qClient binary for testnet downloaded and permissions configured completed."
echo

# Step 5:Determine the ExecStart line based on the architecture
# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/testnet/ceremonyclient/node"
EXEC_START="$NODE_PATH/node"

# Step 6:Create Ceremonyclient Service
echo "⏳ Stopping Ceremonyclient Service"
service ceremonyclient stop
sleep 2  # Add a 2-second delay

echo "⏳ Creating Ceremonyclient Testnet Service"
sleep 2  # Add a 2-second delay

sudo tee /lib/systemd/system/qtest.service > /dev/null <<EOF
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

sudo systemctl daemon-reload
# sudo systemctl enable ceremonyclient

# Step 7: Start the ceremonyclient service
echo "✅Starting Ceremonyclient Testnet Service"
sleep 1  # Add a 1-second delay
sudo service qtest start

# Step 8: See the logs of the ceremonyclient service
echo "🎉Welcome to Quilibrium testnet node $VERSION"
echo "⏳ Waiting 60 seconds to the edit the generated config.yml file"
sleep 60  # Add a 5-second delay

echo
echo "⏳ Editing config.yml file"
CONFIG_FILE="$HOME/testnet/ceremonyclient/node/.config/config.yml"

# Backup the original file
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Comment out existing bootstrap peers
sed -i '/bootstrapPeers:/,/^[^ ]/s/^  -/#  -/' "$CONFIG_FILE"

# Add the new bootstrap peer
sed -i '/bootstrapPeers:/a\  - /ip4/91.242.214.79/udp/8336/quic-v1/p2p/QmNSGavG2DfJwGpHmzKjVmTD6CVSyJsUFTXsW4JXt2eySR' "$CONFIG_FILE"

echo "Bootstrap peers updated in $CONFIG_FILE"
echo "Original file backed up as ${CONFIG_FILE}.bak"

sudo service qtest restart
sudo journalctl -u qtest.service -f --no-hostname -o cat