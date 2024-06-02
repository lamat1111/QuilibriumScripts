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

# Set CPU limit percent
CPU_LIMIT_PERCENT=70

# Exit on any error
set -e

# Step 1: Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "🔄 You can try to run the script from scratch again."
    echo "🛠️ If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}
trap exit_message ERR

# Step 2: Backup existing configuration files if they exist
if [ -d ~/ceremonyclient ]; then
    mkdir -p ~/backup/qnode_keys
    [ -f ~/ceremonyclient/node/.config/keys.yml ] && cp ~/ceremonyclient/node/.config/keys.yml ~/backup/qnode_keys/ && echo "✅ Backup of keys.yml created in ~/backup/qnode_keys folder"
    [ -f ~/ceremonyclient/node/.config/config.yml ] && cp ~/ceremonyclient/node/.config/config.yml ~/backup/qnode_keys/ && echo "✅ Backup of config.yml created in ~/backup/qnode_keys folder"
fi

# Step 3: Download Ceremonyclient
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

# Step 4: Set up environment variables
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Step 5: Verify if go is correctly installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed or not found in PATH"
    exit 1
fi

# Step 6: Build Ceremonyclient qClient
echo "⏳ Building qClient..."
sleep 1  # Add a 1-second delay
cd ~/ceremonyclient/client
GOEXPERIMENT=arenas go build -o qclient main.go
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Step 7: Set the version number
VERSION=$(cat config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Step 8: Get the system architecture
ARCH=$(uname -m)

# Step 9: Determine the ExecStart line based on the architecture
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
CPUQuota='${CPU_QUOTA}'%

[Install]
WantedBy=multi-user.target
EOF

# Step 11: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient && sudo systemctl start ceremonyclient
if [ $? -eq 0 ]; then
    echo "✅ Ceremonyclient Service started successfully."
else
    echo "❌ Failed to start Ceremonyclient Service."
fi

# Step 12: Final messages
echo "✅ A CPU limit of $CPU_LIMIT_PERCENT % has been automatically applied"
echo "✅ You can change this manually later in your service file if you need"
echo ""
echo "🎉 Now your node is starting!"
echo "🕒 Let it run for at least 30 minutes to generate your keys."
echo ""
echo "🔐 You can logout of your server if you want and login again later."
echo "🔒 After 30 minutes, backup your keys.yml and config.yml files."
echo "ℹ️ More info about this in the online guide: https://docs.quilibrium.one"
echo ""
echo "📜 Showing the node log...(CTRL +C to exit)"
echo ""
# Step 13: See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
