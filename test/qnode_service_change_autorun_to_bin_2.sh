#!/bin/bash

#Comment out for automatic creation of the node version
#NODE_VERSION=2.0

#BUGS!!!
# 


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
                    ✨ QNODE SERVICE FILE UPDATER ✨
===========================================================================
This script will update your service file for running the node directly
via binary and will add settings to stop the node gracefully 
in order to avoid penalties.

Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 3

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
    else
        echo "✅ $1 is installed"
    fi
}

# For DEBIAN OS - Check if sudo, git, and curl are installed
check_and_install sudo
check_and_install git
check_and_install curl

sleep 1

echo

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


# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi

sleep 1

#==========================
# SERVICE UPDATE
#==========================

#Set variables
HOME=$(eval echo ~$HOME_DIR)

NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/$NODE_BINARY"

SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Check if the node is running via cluster script or para.sh and skip
if [ -f "$SERVICE_FILE" ] && (grep -q "ExecStart=/root/scripts/qnode_cluster_run.sh" "$SERVICE_FILE" || grep -q "ExecStart=.*para\.sh" "$SERVICE_FILE"); then
    echo "⚠️ You are running a cluster or para.sh script. Skipping service file update..."
    echo
else
    # Build service file
    echo "⏳ Rebuilding Ceremonyclient Service..."
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
ExecStop=/bin/kill -s SIGINT $MAINPID
KillSignal=SIGINT
FinalKillSignal=SIGINT
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF
        then
            echo "❌ Error: Failed to create ceremonyclient service file." >&2
            exit 1
        fi
    else
        echo "⏳ Checking existing ceremonyclient service file..."  

        # Function to add or update a line in the [Service] section
        # Function to add or update a line in the [Service] section
        update_service_section() {
            local key="$1"
            local value="$2"
            if grep -q "^$key=" "$SERVICE_FILE"; then
                current_value=$(grep "^$key=" "$SERVICE_FILE" | cut -d'=' -f2-)
                if [ "$current_value" != "$value" ]; then
                    echo "⏳ Updating $key from $current_value to $value in the service file..."
                    sudo sed -i "s|^$key=.*|$key=$value|" "$SERVICE_FILE"
                else
                    echo "✅ $key=$value already exists and is correct."
                fi
            else
                echo "⏳ Adding $key=$value to the service file..."
                sudo sed -i "/^\[Service\]/,/^\[Install\]/ {
                    /^$/,/^\[Install\]/ {
                        /^$/i $key=$value
                        /^\[Install\]/i \\

                    }
                }" "$SERVICE_FILE"
            fi
        }

        # Function to ensure proper formatting of the service file
        ensure_proper_formatting() {
            # Remove any duplicate empty lines
            sudo sed -i '/^$/N;/^\n$/D' "$SERVICE_FILE"
            
            # Ensure there's exactly one empty line before [Install]
            sudo sed -i '/^\[Install\]/i \\' "$SERVICE_FILE"
            sudo sed -i '/^\[Install\]/!{/^$/N;/^\n$/D}' "$SERVICE_FILE"
        }

        # Update all required lines in the [Service] section
        update_service_section "WorkingDirectory" "$NODE_PATH"
        update_service_section "ExecStart" "$EXEC_START"
        update_service_section "ExecStop" "/bin/kill -s SIGINT \$MAINPID"
        update_service_section "KillSignal" "SIGINT"
        update_service_section "FinalKillSignal" "SIGINT"
        update_service_section "TimeoutStopSec" "30s"

        # Ensure proper formatting after all updates
        ensure_proper_formatting
    fi
fi

sleep 1

# Show the current service file
echo
echo "Showing your updated service file:"
echo "================================="
cat /lib/systemd/system/ceremonyclient.service
echo "================================="
echo

sleep 1
# Ask for user confirmation
read -p "Is everything correct in the service file? (Y/N): " confirm

if [[ $confirm == [Yy]* ]]; then
    echo "⏳ Reloading daemon and restarting the node to apply the new settings..."
    sudo systemctl daemon-reload
    sudo systemctl restart ceremonyclient
    echo "✅ Service file update completed and applied."
else
    echo "Please manually correct the service file at /lib/systemd/system/ceremonyclient.service"
    echo "After corrections, please run the following commands:"
    echo "sudo systemctl daemon-reload"
    echo "sudo systemctl restart ceremonyclient"
fi
