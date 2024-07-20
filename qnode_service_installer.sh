#!/bin/bash

# Step 0: Welcome

#Node version is not used - executiu via release_autorun 
#Comment out for automatic creation of the node version
#NODE_VERSION=1.4.21

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=1.4.19.1

cat << "EOF"

                  QQQQQQQQQ       1111111   
                QQ:::::::::QQ    1::::::1   
              QQ:::::::::::::QQ 1:::::::1   
             Q:::::::QQQ:::::::Q111:::::1   
             Q::::::O   Q::::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O  QQQQ:::::Q   1::::l   
             Q::::::O Q::::::::Q   1::::l   
             Q:::::::QQ::::::::Q111::::::111
              QQ::::::::::::::Q 1::::::::::1
                QQ:::::::::::Q  1::::::::::1
                  QQQQQQQQ::::QQ111111111111
                          Q:::::Q           
                           QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


===================================================================
                 ✨ QNODE SERVICE INSTALLER ✨
===================================================================
This script will install your Quilibrum node as a service.
It will run your node from the release_autostart.sh file.

Be sure to run the 'Server Setup' script first.
Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

Processing... ⏳

EOF

sleep 7  # Add a 7-second delay

#==========================
# CREATE PATH VARIABLES
#==========================

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine node latest version
# Check if NODE_VERSION is empty
if [ -z "$NODE_VERSION" ]; then
    # new version withoout tail and sortng -to be tested
    #NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)
    #new version end
    NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | sort -V | tail -n 1)
    echo "✅ Automatically determined NODE_VERSION: $NODE_VERSION"
else
    echo "✅ Using specified NODE_VERSION: $NODE_VERSION"
fi

# Determine qclient latest version
if [ -z "$QCLIENT_VERSION" ]; then
    # new version withoout tail and sortng -to be tested
    #QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
    # new version end
    QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 | sort -V | tail -n 1)
    echo "✅ Automatically determined QCLIENT_VERSION: $QCLIENT_VERSION"
else
    echo "✅ Using specified QCLIENT_VERSION: $QCLIENT_VERSION"
fi

echo

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
        GO_BINARY="go1.22.4.darwin-amd64.tar.gz"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
        GO_BINARY="go1.22.4.darwin-arm64.tar.gz"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
fi


# Exit on any error
set -e

# Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "You can try to run the script from scratch again."
    echo
    echo "If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
    echo "The step by step installation instructions are here: https://iri.quest/q-node-step-by-step"
}

# Set a trap to call exit_message on any error
trap exit_message ERR

# Fof DEBIAN OS - Check if sudo and git is installed
if ! command -v sudo &> /dev/null
then
    echo "sudo could not be found"
    echo "⏳ Installing sudo..."
    su -c "apt update && apt install sudo -y"
    echo
else
    echo "✅ sudo is installed"
    echo
fi

if ! command -v git &> /dev/null
then
    echo "git could not be found"
    echo "⏳ Installing git..."
    su -c "apt update && apt install git -y"
    echo
else
    echo "✅ git is installed"
    echo
fi

# Backup existing configuration files if they exist
if [ -d ~/ceremonyclient ]; then
    mkdir -p ~/backup/qnode_keys
    [ -f ~/ceremonyclient/node/.config/keys.yml ] && cp ~/ceremonyclient/node/.config/keys.yml ~/backup/qnode_keys/ && echo "✅ Backup of keys.yml created in ~/backup/qnode_keys folder"
    [ -f ~/ceremonyclient/node/.config/config.yml ] && cp ~/ceremonyclient/node/.config/config.yml ~/backup/qnode_keys/ && echo "✅ Backup of config.yml created in ~/backup/qnode_keys folder"
    echo
fi

# Download Ceremonyclient
echo "⏳ Downloading Ceremonyclient..."
sleep 1  # Add a 1-second delay
cd ~
if [ -d "ceremonyclient" ]; then
  echo "Directory ceremonyclient already exists, skipping git clone..."
else
  until git clone https://github.com/QuilibriumNetwork/ceremonyclient.git || git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git; do
    echo "Git clone failed, retrying..."
    sleep 2
  done
fi
cd ~/ceremonyclient/
git checkout release
echo

# Set up environment variables (redundant but solves the command go not found error)
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Building qClient with GO
# echo "⏳ Building qCiient..."
# sleep 1  # Add a 1-second delay
# cd ~/ceremonyclient/client
# GOEXPERIMENT=arenas go build -o qclient main.go

# Building qClient binary
echo "⏳ Downloading qClient..."
sleep 1  # Add a 1-second delay
cd ~/ceremonyclient/client

if ! wget https://releases.quilibrium.com/$QCLIENT_BINARY; then
    echo "❌ Error: Failed to download qClient binary."
    echo "Your node will still work, you can install the qclient manually later."
    echo
else
    mv $QCLIENT_BINARY qclient
    chmod +x qclient
    echo "✅ qClient binary downloaded successfully."
    echo
fi

# Get the current user's home directory
HOME=$(eval echo ~$USER)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Step 6: Create Ceremonyclient Service
echo "⏳ Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay

# Calculate GOMAXPROCS based on the system's RAM
calculate_gomaxprocs() {
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    local gomaxprocs=$((ram_gb / 2))
    if [ $gomaxprocs -gt $cpu_cores ]; then
        gomaxprocs=$cpu_cores
    fi
    gomaxprocs=$((gomaxprocs + 1))
    echo $gomaxprocs
}

GOMAXPROCS=$(calculate_gomaxprocs)

echo "✅ GOMAXPROCS has been set to $GOMAXPROCS based on your server's resources."
echo

# Check if the file exists before attempting to remove it
if [ -f "/lib/systemd/system/ceremonyclient.service" ]; then
    rm /lib/systemd/system/ceremonyclient.service
    echo "ceremonyclient.service file removed."
else
    echo "ceremonyclient.service file does not exist. No action taken."
fi

sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
Environment="GOMAXPROCS=$GOMAXPROCS"

[Install]
WantedBy=multi-user.target
EOF

# Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
echo

sleep 2  # Add a 2-second delay
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo service ceremonyclient start

# Final messages
echo "✅ Now your node is starting!"
echo "Let it run for at least 15-30 minutes to generate your keys."
echo
echo "✅ You can logout of your server if you want and login again later."
echo
echo "After 30 minutes, backup your keys.yml and config.yml files."
echo "The proceed to set up your gRPC calls,"
echo "and lastly set up an automatic backup for your .config folder"
echo "More info about all this in the online guide: https://docs.quilibrium.one"
echo
echo "⏳ Now I will show the node log below..."
echo "To exit the log, just type CTRL +C."

# See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
