#!/bin/bash

# Set CPU limit percent
CPU_LIMIT_PERCENT=80

echo ""
echo ""
echo "====================================================================================================="
echo "                                  ✨ QUILIBRIUM NODE INSTALLER ✨"
echo "====================================================================================================="
echo "This script will install your node as a service. It will run your node form the binary file."
echo "It will also disable HT (Hyper Threading), and it will set a CPUQuota limit of $CPU_LIMIT_PERCENT %"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================================="
echo ""
echo "Processing... ⏳"
sleep 5
echo ""

# Exit on any error
set -e

# Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "🔄 You can try to run the script from scratch again."
    echo "🛠️ If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}
trap exit_message ERR

# Backup existing configuration files if they exist
if [ -d ~/ceremonyclient ]; then
    mkdir -p ~/backup/qnode_keys
    [ -f ~/ceremonyclient/node/.config/keys.yml ] && cp ~/ceremonyclient/node/.config/keys.yml ~/backup/qnode_keys/ && echo "✅ Backup of keys.yml created in ~/backup/qnode_keys folder"
    [ -f ~/ceremonyclient/node/.config/config.yml ] && cp ~/ceremonyclient/node/.config/config.yml ~/backup/qnode_keys/ && echo "✅ Backup of config.yml created in ~/backup/qnode_keys folder"
fi

# ==================
# Disable Hyper-Threading (SMT)
# ==================
echo "⚙️ Disabling Hyper-Threading (SMT)..."
sleep 1

# Check the current state of SMT
SMT_STATE=$(cat /sys/devices/system/cpu/smt/active)

# If SMT is already disabled, print a message and skip to the next step
if [ "$SMT_STATE" -eq 0 ]; then
    echo "✅ Hyper-Threading (SMT) is already disabled. Skipping to the next step."
else
    # Disable SMT
    echo off | sudo tee /sys/devices/system/cpu/smt/control

    # Check if SMT is now disabled
    UPDATED_STATE=$(cat /sys/devices/system/cpu/smt/active)

    # Print success message if SMT is successfully disabled
    if [ "$UPDATED_STATE" -eq 0 ]; then
        echo "✅ Hyper-Threading (SMT) has been successfully disabled."
    else
        echo "❌ Failed to disable Hyper-Threading (SMT)."
        # You can add error handling or exit the script here if needed
    fi
fi

sleep 1

# ==================
# Download Ceremonyclient
# ==================
echo "⏳ Downloading Ceremonyclient"
sleep 1  # Add a 1-second delay
cd ~
if [ -d "ceremonyclient" ]; then
  echo "Directory ceremonyclient already exists, skipping git clone..."
else
  attempt=0
  max_attempts=3
  while [ $attempt -lt $max_attempts ]; do
    if git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://source.quilibrium.com/quilibrium/ceremonyclient.git"
      break
    elif git clone https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git"
      break
    elif git clone https://github.com/QuilibriumNetwork/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://github.com/QuilibriumNetwork/ceremonyclient.git"
      break
    else
      attempt=$((attempt+1))
      echo "Git clone failed (attempt $attempt of $max_attempts), retrying..."
      sleep 2
    fi
  done

  if [ $attempt -ge $max_attempts ]; then
    echo "❌ Error: Failed to clone the repository after $max_attempts attempts." >&2
    exit 1
  fi
fi

cd ~/ceremonyclient/
git checkout release

# Set up environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Verify if go is correctly installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed or not found in PATH"
    exit 1
fi

# Build Ceremonyclient qClient
echo "⏳ Building qClient..."
sleep 1  # Add a 1-second delay
cd ~/ceremonyclient/client
GOEXPERIMENT=arenas go build -o qclient main.go
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# ==================
# Setup service file
# ==================
# Set the version number

VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Get the system architecture
ARCH=$(uname -m)

# Determine the ExecStart line based on the architecture
HOME=$(eval echo ~$USER)
NODE_PATH="$HOME/ceremonyclient/node"

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Step 10: Create Ceremonyclient Service
echo "⏳ Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay

if [ -f "/lib/systemd/system/ceremonyclient.service" ]; then
    sudo rm /lib/systemd/system/ceremonyclient.service
    echo "ceremonyclient.service file removed."
else
    echo "ceremonyclient.service file does not exist. No action taken."
fi

# Calculate the number of vCores
vCORES=$(nproc)

# Calculate the CPUQuota value
CPU_QUOTA=$(($CPU_LIMIT_PERCENT * $vCORES))

sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
CPUQuota=${CPU_QUOTA}%
ExecStartPre=/bin/sh -c 'echo off | tee /sys/devices/system/cpu/smt/control'

[Install]
WantedBy=multi-user.target
EOF

# ==================
# Start service and final messages
# ==================

# Start service
echo "✅ Starting Ceremonyclient Service"
sleep 2
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient && sudo systemctl start ceremonyclient
if [ $? -eq 0 ]; then
    echo "✅ Ceremonyclient Service started successfully."
else
    echo "❌ Failed to start Ceremonyclient Service."
fi

# Final messages
echo "✅ You are now using $vCORES cores"
echo "✅ A CPU limit of $CPU_LIMIT_PERCENT % has been automatically applied"
echo "✅ You can change this manually later in your service file if you need"
echo ""
echo "✅ Now your node is starting!"
echo "ℹ️ Let it run for at least 30 minutes to generate your keys."
echo ""
echo "ℹ️ You can logout of your server if you want and login again later."
echo "ℹ️ After 30 minutes, backup your keys.yml and config.yml files."
echo "ℹ️ More info about this in the online guide: https://docs.quilibrium.one"
echo ""
echo "ℹ️ Showing the node log...(CTRL +C to exit)"
echo ""
# Step 13: See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
