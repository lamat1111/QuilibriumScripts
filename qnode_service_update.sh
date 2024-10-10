#!/bin/bash

#Node version is not used - execution via release_autorun 
#Comment out for automatic creation of the node version
#NODE_VERSION=2.0

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

                              
===========================================================================
                       ✨ QNODE SERVICE UPDATER ✨
===========================================================================
This script will update your Quilibrium node when running it as a service.
It will run your node from the release_autostart.sh file.

Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 5  # Add a 7-second delay

#==========================
# INSTALL APPS
#==========================

# Function to check and install a package
check_and_install() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        echo "⏳ Installing $1..."
        su -c "apt install $1 -y"
        echo
    else
        echo "✅ $1 is installed"
        echo
    fi
}

# For DEBIAN OS - Check if sudo, git, and curl are installed
check_and_install sudo
check_and_install git
check_and_install curl


#==========================
# CREATE PATH VARIABLES
#==========================

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine node latest version
# Check if NODE_VERSION is empty
if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)
    if [ -z "$NODE_VERSION" ]; then
        echo "❌ Error: Unable to determine NODE_VERSION automatically."
        echo "The script cannot proceed without a correct node version number." 
        echo "Please try the manual step by step installation instead:"
        echo "https://docs.quilibrium.one/start/tutorials/node-step-by-step-installation"
        echo
        exit 1
    else
        echo "✅ Automatically determined NODE_VERSION: $NODE_VERSION"
    fi
else
    echo "✅ Using specified NODE_VERSION: $NODE_VERSION"
fi

# Determine qclient latest version
# Check if QCLIENT_VERSION is empty
if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
    if [ -z "$QCLIENT_VERSION" ]; then
        echo "⚠️ Warning: Unable to determine QCLIENT_VERSION automatically. Continuing without it."
        echo "The script won't be able to install the qclient, but it will still install your node."
        echo "You can install the qclient later manually if you need to."
        echo
        sleep 1
    else
        echo "✅ Automatically determined QCLIENT_VERSION: $QCLIENT_VERSION"
    fi
else
    echo "✅ Using specified QCLIENT_VERSION: $QCLIENT_VERSION"
fi

echo

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
        GO_BINARY="go1.22.4.darwin-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
        GO_BINARY="go1.22.4.darwin-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi

#==========================
# GO UPGRADE
#==========================

# Check the currently installed Go version
if go version &>/dev/null; then
    INSTALLED_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
else
    INSTALLED_VERSION="none"
fi

# If the installed version is not 1.22.4, proceed with the installation
if [ "$INSTALLED_VERSION" != "1.22.4" ]; then
    echo "⏳ Current Go version is $INSTALLED_VERSION. Proceeding with installation of Go 1.22.4..."

    # Download and install Go
    wget https://go.dev/dl/$GO_BINARY > /dev/null 2>&1 || echo "Failed to download Go!"
    sudo tar -xvf $GO_BINARY > /dev/null 2>&1 || echo "Failed to extract Go!"
    sudo rm -rf /usr/local/go || echo "Failed to remove existing Go!"
    sudo mv go /usr/local || echo "Failed to move Go!"
    sudo rm $GO_BINARY || echo "Failed to remove downloaded archive!"
    
    echo "✅ Go 1.22.4 has been installed successfully."
    echo
else
    echo "✅ Go version 1.22.4 is already installed. No action needed."
    echo
fi

#==========================
# NODE UPDATE
#==========================

# Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl is-active --quiet ceremonyclient && service ceremonyclient stop; then
    echo "🔴 Service stopped successfully."
    echo
else
    echo "❌ Ceremonyclient service either does not exist or could not be stopped." >&2
    echo
fi
sleep 1

# Discard local changes in release_autorun.sh
# echo "✅ Discarding local changes in release_autorun.sh..."
# echo
# git checkout -- node/release_autorun.sh

# Set the remote URL and download
echo "⏳ Downloading new release v$NODE_VERSION"
cd  ~/ceremonyclient
git remote set-url origin https://github.com/QuilibriumNetwork/ceremonyclient.git
#git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git || git remote set-url origin https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git
git checkout main
git branch -D release
git pull
git checkout release
echo "✅ Downloaded the latest changes successfully."
echo

#==========================
# QCLIENT UPDATE
#==========================

# Building qClient binary
if [ -n "$QCLIENT_BINARY" ]; then
    echo "⏳ Downloading qClient..."
    sleep 1  # Add a 1-second delay
    cd ~/ceremonyclient/client

    if ! wget https://releases.quilibrium.com/$QCLIENT_BINARY; then
        echo "❌ Error: Failed to download qClient binary."
        echo "Your node will still work, but you'll need to install the qclient manually later if needed."
        echo
    else
        mv $QCLIENT_BINARY qclient
        chmod +x qclient
        echo "✅ qClient binary downloaded successfully."
        echo
    fi
else
    echo "ℹ️ Skipping qClient download as QCLIENT_BINARY could not be determined earlier."
    echo "Your node will still work, but you'll need to install the qclient manually later if needed."
    echo
fi

#==========================
# SERVICE UPDATE
#==========================

#Set variables
HOME=$(eval echo ~$HOME_DIR)

NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Check if the service file exists and contains the specific ExecStart line with any parameters
if [ -f "$SERVICE_FILE" ] && grep -q "ExecStart=/root/scripts/qnode_cluster_run.sh" "$SERVICE_FILE"; then
    echo "⚠️ You are runnig a cluster. Skipping service file update..."
    echo
else
    echo "⏳ Rebuilding Ceremonyclient Service..."
    echo
    sleep 1

    if [ ! -f "$SERVICE_FILE" ]; then
        echo "⏳ Creating new ceremonyclient service file..."
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
        echo "⏳ Checking existing ceremonyclient service file..."
        
        # Check if the required lines exist
        if ! grep -q "WorkingDirectory=$NODE_PATH" "$SERVICE_FILE" || ! grep -q "ExecStart=$EXEC_START" "$SERVICE_FILE"; then
            echo "⏳ Updating existing ceremonyclient service file..."
            # Replace the existing lines with new values
            sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=$NODE_PATH|" "$SERVICE_FILE"
            sudo sed -i "s|ExecStart=.*|ExecStart=$EXEC_START|" "$SERVICE_FILE"
        else
            echo "✅ No changes needed."
        fi
    fi
fi

# The script continues here with any code that should run after the conditional block
echo "Continuing with the rest of the script..."

echo

#==========================
# CONFIG FILE UPDATE for "REWARDS TO GOOGLE SHEET SCRIPT"
#==========================

# Function to update config file
update_config_file() {
    local config_file=$1
    echo "✅ Checking node version in config file '$(basename "$config_file")'."
    sleep 1
    # Get the current NODE_BINARY from the config file
    config_node_binary=$(grep "NODE_BINARY=" "$config_file" | cut -d '=' -f 2)
    # Compare NODE_BINARY values
    if [ "$config_node_binary" = "$NODE_BINARY" ]; then
        echo "NODE_BINARY values match. No update needed."
    else
        echo "⏳ NODE_BINARY values differ. Updating config file..."
        
        # Update the config file
        sed -i "s|NODE_BINARY=.*|NODE_BINARY=$NODE_BINARY|" "$config_file"
        
        if [ $? -eq 0 ]; then
            echo "✅ Config file updated successfully."
        else
            echo "❌ Failed to update config file. Continuing to next step..."
        fi
    fi
}

# Array of config files
config_files=(
    "~/scripts/qnode_rewards_to_gsheet.config"
    "~/scripts/qnode_rewards_to_gsheet_2.config"
)

# Loop through config files
for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        update_config_file "$config_file"
    else
        echo "Config file not found: $config_file"
        echo "This is not a problem (it's not related to your node). Continuing to next file..."
    fi
done

echo "All config files processed."

echo

#==========================
# START NODE VIA SERVICE
#==========================

echo "✅ Starting Ceremonyclient Service"
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo service ceremonyclient start

# Showing the node version and logs
echo "🌟Your node is now updated to v$NODE_VERSION !"
echo
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo
echo
sleep 2
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
