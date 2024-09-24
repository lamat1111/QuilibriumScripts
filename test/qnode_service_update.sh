#!/bin/bash

#Node version is not used - execution via release_autorun 
#Comment out for automatic creation of the node version
#NODE_VERSION=1.4.21.1

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

sleep 7  # Add a 7-second delay

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
# NODE AND QCLIENT VERSIONS
#==========================

determine_version() {
    local version_type=$1
    local url=$2
    local grep_pattern=$3
    
    VERSION=$(curl -s "$url" | grep -E "$grep_pattern" | sed "s/^$version_type-//" | cut -d '-' -f 1 | head -n 1)
    echo "$VERSION"
}

modify_nameservers() {
    echo "Modifying nameservers to 8.8.8.8..."
    sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    echo "Nameservers modified. Attempting to determine versions again..."
}

manual_input() {
    local version_type=$1
    while true; do
        read -p "Please enter the $version_type manually (format: X.X or X.X.X or X.X.X.X): " VERSION
        if [[ $VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+(\.[0-9]+)?)?$ ]]; then
            component_count=$(echo $VERSION | awk -F. '{print NF}')
            if [ $component_count -ge 2 ] && [ $component_count -le 4 ]; then
                echo "✅ Using manually entered $version_type: $VERSION"
                break
            else
                echo "Invalid number of version components. Please use 2, 3, or 4 components."
            fi
        else
            echo "Invalid format. Please enter the version as X.X or X.X.X or X.X.X.X"
        fi
    done
    echo "$VERSION"
}

handle_error() {
    local version_type=$1
    local allow_skip=$2  # New parameter to control skip option

    while true; do
        echo "❌ Error: Unable to determine $version_type automatically."
        echo "Please choose an option:"
        echo "1 - Modify nameservers to 8.8.8.8 (can help on some providers)"
        echo "2 - Input $version_type manually"
        if [ "$allow_skip" = true ]; then
            echo "3 - Skip $version_type determination"
            echo "4 - Exit script"
        else
            echo "3 - Exit script"
        fi
        read -p "Enter your choice: " choice

        case $choice in
            1)
                modify_nameservers
                return 1  # Signal to retry version determination
                ;;
            2)
                VERSION=$(manual_input "$version_type")
                echo "$VERSION"
                return 0
                ;;
            3)
                if [ "$allow_skip" = true ]; then
                    echo ""  # Return empty string to skip
                    return 0
                else
                    echo "Exiting script. Please try the manual step by step installation instead:"
                    echo "https://docs.quilibrium.com/start/tutorials/node-step-by-step-installation"
                    exit 1
                fi
                ;;
            4)
                if [ "$allow_skip" = true ]; then
                    echo "Exiting script. Please try the manual step by step installation instead:"
                    echo "https://docs.quilibrium.com/start/tutorials/node-step-by-step-installation"
                    exit 1
                else
                    echo "Invalid choice. Please try again."
                fi
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Update the determine_version_with_retry function to include the allow_skip parameter
determine_version_with_retry() {
    local version_type=$1
    local url=$2
    local grep_pattern=$3
    local allow_skip=$4

    VERSION=$(determine_version "$version_type" "$url" "$grep_pattern")
    if [ -z "$VERSION" ]; then
        VERSION=$(handle_error "$version_type" "$allow_skip")
        if [ $? -eq 1 ]; then
            VERSION=$(determine_version "$version_type" "$url" "$grep_pattern")
            if [ -z "$VERSION" ]; then
                VERSION=$(handle_error "$version_type" "$allow_skip")
            fi
        fi
    fi
    echo "$VERSION"
}

# Main script execution
if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION=$(determine_version_with_retry "NODE_VERSION" "https://releases.quilibrium.com/release" "^node-[0-9]+(\.[0-9]+)*" false)
    if [ -n "$NODE_VERSION" ]; then
        echo "✅ Determined NODE_VERSION: $NODE_VERSION"
    fi
else
    echo "✅ Using specified NODE_VERSION: $NODE_VERSION"
fi

if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(determine_version_with_retry "QCLIENT_VERSION" "https://releases.quilibrium.com/qclient-release" "^qclient-[0-9]+(\.[0-9]+)*" true)
    if [ -n "$QCLIENT_VERSION" ]; then
        echo "✅ Determined QCLIENT_VERSION: $QCLIENT_VERSION"
    else
        echo "⚠️ Warning: Unable to determine QCLIENT_VERSION. Continuing without it."
        echo "The script won't be able to install the qclient, but it will still install your node."
        echo "You can install the qclient later manually if you need to."
    fi
else
    echo "✅ Using specified QCLIENT_VERSION: $QCLIENT_VERSION"
fi
echo

#==========================
# NODE BINARY NAMES
#==========================

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

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

# Step 1: Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl is-active --quiet ceremonyclient && service ceremonyclient stop; then
    echo "🔴 Service stopped successfully."
    echo
else
    echo "❌ Ceremonyclient service either does not exist or could not be stopped." >&2
    echo
fi
sleep 1

# Step 2: Move to the ceremonyclient directory
echo "⏳ Moving to the ceremonyclient directory..."
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient does not exist."; exit 1; }
echo

# Step 3: Discard local changes in release_autorun.sh
echo "✅ Discarding local changes in release_autorun.sh..."
echo
git checkout -- node/release_autorun.sh

# Step 4: Download Binary
echo "⏳ Downloading new release v$NODE_VERSION"
echo

# Set the remote URL and download
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

# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Re-Create or Update Ceremonyclient Service
echo "⏳ Rebuilding Ceremonyclient Service..."
echo
sleep 2  # Add a 2-second delay
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
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
        echo "Not a problem! Continuing to next file..."
    fi
done

echo "All config files processed."

echo

#==========================
# START NODE VIA SERVICE
#==========================

# Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Showing the node version and logs
echo "🌟Your node is now updated to v$NODE_VERSION !"
echo
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo
echo
sleep 3  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
