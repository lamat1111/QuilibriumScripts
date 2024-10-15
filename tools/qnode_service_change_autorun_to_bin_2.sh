#!/bin/bash

#Comment out for automatic creation of the node version
#NODE_VERSION=2.0


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
TEMP_SERVICE_FILE="/tmp/ceremonyclient_temp.service"

# Function to add or update a line in the [Service] section
update_service_section() {
    local key="$1"
    local value="$2"
    local file="$3"
    if grep -q "^$key=" "$file"; then
        current_value=$(grep "^$key=" "$file" | cut -d'=' -f2-)
        if [ "$current_value" != "$value" ]; then
            echo "⏳ Updating $key from $current_value to $value in the service file..."
            sed -i "s|^$key=.*|$key=$value|" "$file"
        else
            echo "✅ $key=$value already exists and is correct."
        fi
    else
        echo "⏳ Adding $key=$value to the service file..."
        sed -i "/^\[Service\]/,/^\[Install\]/ {
            /^\[Install\]/i $key=$value
        }" "$file"
    fi
}

# Function to ensure a single empty line at the end of each section
ensure_section_formatting() {
    local file="$1"
    sed -i '
        /^\[.*\]/ {
            N
            /\n$/!s/$/\n/
        }
        /^\[Install\]/ {
            N
            /\n$/!s/$/\n/
        }
    ' "$file"
}

# Check if the node is running via cluster script or para.sh and skip
if [ -f "$SERVICE_FILE" ] && (grep -q "ExecStart=/root/scripts/qnode_cluster_run.sh" "$SERVICE_FILE" || grep -q "ExecStart=.*para\.sh" "$SERVICE_FILE"); then
    echo "⚠️ You are running a cluster or para.sh script. Skipping service file update..."
    echo
    exit 0
fi

# Create a temporary service file for dry run
if [ -f "$SERVICE_FILE" ]; then
    cp "$SERVICE_FILE" "$TEMP_SERVICE_FILE"
else
    cat > "$TEMP_SERVICE_FILE" <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
fi

# Update all required lines in the [Service] section
update_service_section "WorkingDirectory" "$NODE_PATH" "$TEMP_SERVICE_FILE"
update_service_section "ExecStart" "$EXEC_START" "$TEMP_SERVICE_FILE"
update_service_section "ExecStop" "/bin/kill -s SIGINT \$MAINPID" "$TEMP_SERVICE_FILE"
update_service_section "ExecReload" "/bin/kill -s SIGINT \$MAINPID && $EXEC_START" "$TEMP_SERVICE_FILE"
update_service_section "KillSignal" "SIGINT" "$TEMP_SERVICE_FILE"
update_service_section "RestartKillSignal" "SIGINT" "$TEMP_SERVICE_FILE"
update_service_section "FinalKillSignal" "SIGKILL" "$TEMP_SERVICE_FILE"
update_service_section "TimeoutStopSec" "30s" "$TEMP_SERVICE_FILE"

# Ensure proper formatting with a single empty line at the end of each section
ensure_section_formatting "$TEMP_SERVICE_FILE"

# Show the proposed service file
echo
echo "Proposed changes to the service file:"
echo "====================================="
cat "$TEMP_SERVICE_FILE"
echo "====================================="
echo

# Ask for user confirmation
read -p "Do you want to apply these changes? (Y/N): " confirm

if [[ $confirm == [Yy]* ]]; then
    echo "⏳ Applying changes to the actual service file..."
    sudo cp "$TEMP_SERVICE_FILE" "$SERVICE_FILE"
    echo "⏳ Reloading daemon and restarting the node to apply the new settings..."
    sudo systemctl daemon-reload
    sudo systemctl restart ceremonyclient
    echo "✅ Service file update completed and applied."
else
    echo "Changes were not applied. The current service file remains unchanged."
fi

# Clean up temporary file
rm "$TEMP_SERVICE_FILE"
