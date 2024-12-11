#!/bin/bash

cat << "EOF"

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
                       ✨ QNODE FORCED UPDATER ✨
===========================================================================
This script will forcefully update your Quilibrium node when running it as a service.
It will run your node from the binary file, and you will have to
update manually.
Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

              ⚠️ THIS SCRIPT DOES NOT SUPPORT CLUSTERS! ⚠️
        if you are running a node cluster press 'CTRL+C' immediately

---------------------------------------------------------------------------

⏳ Processing... 

EOF

sleep 7  

SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Check if the service file exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "❌ Error: you are not running your node via service file:  $SERVICE_FILE"
    echo "This update script won't work for you. Exiting."
    exit 1
fi

# Function to display section headers
display_header() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
    echo
}

#==========================
# INSTALL APPS
#==========================

display_header "INSTALLING REQUIRED APPLICATIONS"

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

#==========================
# CREATE PATH VARIABLES
#==========================

display_header "PREPARING FOR UPDATE"

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine node latest version
NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)
if [ -z "$NODE_VERSION" ]; then
    echo "❌ Error: Unable to determine the latest node release automatically."
    exit 1
else
    echo "✅ Latest Node release: $NODE_VERSION"
fi

# Determine qclient latest version
QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
if [ -z "$QCLIENT_VERSION" ]; then
    echo "❌ Error: Unable to determine the latest Qclient release automatically."
    exit 1
else
    echo "✅ Latest Qclient release: $QCLIENT_VERSION"
fi

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
        QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi

get_os_arch() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case "$os" in
        linux|darwin) ;;
        *) echo "Unsupported operating system: $os" >&2; return 1 ;;
    esac

    case "$arch" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "Unsupported architecture: $arch" >&2; return 1 ;;
    esac

    echo "${os}-${arch}"
}

# Get the current OS and architecture
OS_ARCH=$(get_os_arch)

echo

#==========================
# STOP SERVICE
#==========================

display_header "STOPPING SERVICE"

# Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service..."
if systemctl is-active --quiet ceremonyclient; then
    if sudo systemctl stop ceremonyclient; then
        echo "✅ Service stopped successfully."
        echo
    else
        echo "❌ Failed to stop the ceremonyclient service." >&2
        echo
    fi
else
    echo "⚠️ Ceremonyclient service is not active or does not exist."
    echo
fi
sleep 1

#==========================
# NODE BINARY DOWNLOAD
#==========================

display_header "DOWNLOADING NODE BINARY"

# Base URL for the Quilibrium releases
RELEASE_FILES_URL="https://releases.quilibrium.com/release"

# Fetch the list of files from the release page
RELEASE_FILES=$(curl -s $RELEASE_FILES_URL | grep -oE "node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Change to the download directory
cd ~/ceremonyclient/node

# Download each file
for file in $RELEASE_FILES; do
    echo "Downloading $file..."
    if curl -L -o "$file" "https://releases.quilibrium.com/$file" --fail --silent; then
        echo "Successfully downloaded $file"
        # Check if the file is the base binary (without .dgst or .sig suffix)
        if [[ $file =~ ^node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}$ ]]; then
            if chmod +x "$file"; then
                echo "Made $file executable"
            else
                echo "❌ Failed to make $file executable"
            fi
        fi
    else
        echo "❌ Failed to download $file"
    fi
    echo "------------------------"
done

echo "✅ Node binary download completed."

#==========================
# QCLIENT UPDATE
#==========================

display_header "UPDATING QCLIENT"

# Base URL for the Quilibrium releases
BASE_URL="https://releases.quilibrium.com"

# Change to the download directory
if ! cd ~/ceremonyclient/client; then
    echo "❌ Error: Unable to change to the download directory"
    exit 1
fi

# Function to download file and overwrite if it exists
download_and_overwrite() {
    local url="$1"
    local filename="$2"
    if curl -L -o "$filename" "$url" --fail --silent; then
        echo "Successfully downloaded $filename"
        return 0
    else
        return 1
    fi
}

# Download the main binary
echo "Downloading $QCLIENT_BINARY..."
if download_and_overwrite "$BASE_URL/$QCLIENT_BINARY" "$QCLIENT_BINARY"; then
    chmod +x $QCLIENT_BINARY
else
    echo "❌ Failed to download qclient binary. Manual installation may be required."
    exit 1
fi

# Download the .dgst file
echo "Downloading ${QCLIENT_BINARY}.dgst..."
if ! download_and_overwrite "$BASE_URL/${QCLIENT_BINARY}.dgst" "${QCLIENT_BINARY}.dgst"; then
    echo "❌ Failed to download .dgst file. Continuing without it."
fi

# Download signature files
echo "Downloading signature files..."
for i in {1..20}; do
    sig_file="${QCLIENT_BINARY}.dgst.sig.${i}"
    if download_and_overwrite "$BASE_URL/$sig_file" "$sig_file"; then
        echo "Downloaded $sig_file"
    fi
done

echo "✅ Qclient download completed."

#==========================
# SERVICE UPDATE
#==========================

display_header "UPDATING SERVICE" 

NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/$NODE_BINARY"

SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Function to add or update a line in the [Service] section while preserving order and custom lines
update_service_section() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if grep -q "^$key=" "$file"; then
        # If the key exists, update its value
        sudo sed -i "s|^$key=.*|$key=$value|" "$file"
    else
        # If the key doesn't exist, add it before the [Install] section
        sudo sed -i "/^\[Install\]/i $key=$value" "$file"
    fi
}

# Function to ensure correct formatting and order of entries while preserving custom lines
ensure_correct_formatting() {
    local file="$1"
    local temp_file="${file}.temp"
    
    # Copy [Unit] section
    sudo sed -n '1,/^\[Service\]/p' "$file" | sed '/^$/d; /^\[Service\]$/d' > "$temp_file"
    echo >> "$temp_file"
    
    # Start [Service] section
    echo "[Service]" >> "$temp_file"
    
    # Standard keys we want to ensure are in a specific order
    standard_keys="Type Restart RestartSec WorkingDirectory ExecStart ExecStop KillSignal RestartKillSignal FinalKillSignal TimeoutStopSec"
    
    # Add standard keys if they exist
    for key in $standard_keys; do
        grep "^$key=" "$file" >> "$temp_file" || true
    done
    
    # Add any custom lines that aren't part of the standard keys
    sed -n '/^\[Service\]/,/^\[Install\]/p' "$file" | while read line; do
        if [[ $line != \[Service\]* ]] && [[ $line != \[Install\]* ]]; then
            key=$(echo "$line" | cut -d'=' -f1)
            if ! echo "$standard_keys" | grep -q "$key"; then
                echo "$line" >> "$temp_file"
            fi
        fi
    done
    
    echo >> "$temp_file"
    
    # Copy [Install] section
    echo "[Install]" >> "$temp_file"
    sed -n '/^\[Install\]/,$ p' "$file" | grep -v '^\[Install\]' >> "$temp_file"
    
    # Replace original file with temp file
    sudo mv "$temp_file" "$file"
}

# Check if the node is running via cluster script or para.sh and skip
if [ -f "$SERVICE_FILE" ] && (grep -q "ExecStart=/root/scripts/qnode_cluster_run.sh" "$SERVICE_FILE" || grep -q "ExecStart=.*para\.sh" "$SERVICE_FILE"); then
    echo "⚠️ You are running a cluster or para.sh script. Skipping service file update..."
    echo
    exit 0
fi

# Update or create service file
echo "⏳ Updating Ceremonyclient Service..."
if [ ! -f "$SERVICE_FILE" ]; then
    echo "⏳ Creating new ceremonyclient service file..."
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service
StartLimitIntervalSec=0
StartLimitBurst=0

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
ExecStop=/bin/kill -s SIGINT \$MAINPID
KillSignal=SIGINT
RestartKillSignal=SIGINT
FinalKillSignal=SIGKILL
TimeoutStopSec=240s

[Install]
WantedBy=multi-user.target
EOF
else
    echo "⏳ Updating existing ceremonyclient service file..."

    # Update all required lines in the [Service] section
    update_service_section "WorkingDirectory" "$NODE_PATH" "$SERVICE_FILE"
    update_service_section "ExecStart" "$EXEC_START" "$SERVICE_FILE"
    update_service_section "ExecStop" "/bin/kill -s SIGINT \$MAINPID" "$SERVICE_FILE"
    update_service_section "KillSignal" "SIGINT" "$SERVICE_FILE"
    update_service_section "RestartKillSignal" "SIGINT" "$SERVICE_FILE"
    update_service_section "FinalKillSignal" "SIGKILL" "$SERVICE_FILE"
    update_service_section "TimeoutStopSec" "30s" "$SERVICE_FILE"

    # Ensure proper formatting and order
    ensure_correct_formatting "$SERVICE_FILE"
fi

echo "⏳ Reloading daemon and restarting the node to apply the new settings..."
sudo systemctl daemon-reload
sudo systemctl restart ceremonyclient
echo "✅ Service file update completed and applied."

#==========================
# START NODE VIA SERVICE
#==========================

display_header "STARTING NODE"

echo "✅ Starting Ceremonyclient Service"
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo systemctl start ceremonyclient

# Showing the node version and logs
echo "🌟 Your node is now updated to v$NODE_VERSION!"
echo "🌟 Your qclient is now updated to v$QCLIENT_VERSION!"
echo
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo
echo
sleep 2
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat

# This is the end of the script. The last command (journalctl) will run indefinitely
# until the user interrupts it with CTRL+C.