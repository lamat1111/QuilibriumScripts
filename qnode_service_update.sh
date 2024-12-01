#!/bin/bash

SCRIPT_VERSION="2.3"


# Check for sudo privileges immediately
check_sudo() {
    if ! sudo -v &> /dev/null; then
        cat << EOF

❌ Error: This script requires sudo privileges to run properly.
Please run this script again with sudo privileges to ensure proper version detection
and updates.

You can either:
1. Run the script with sudo: sudo bash <script_name>
2. Grant your user sudo privileges and try again

EOF
        exit 1
    fi
}

# Run sudo check before anything else
check_sudo

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
                 ✨ QNODE / QCLIENT UPDATER - $SCRIPT_VERSION ✨
===========================================================================
This script will update your Quilibrium node when running it as a service.
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

#Comment out for automatic creation of the node version
#NODE_VERSION=2.0

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=1.4.19.1

#GO installation yes or no?
INSTALL_GO=false
GO_VERSION=1.23.2
#GIT PULL yes or no?
GIT_PULL=false

#useful variables
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
QUILIBRIUM_RELEASES="https://releases.quilibrium.com"
NODE_RELEASE_URL="https://releases.quilibrium.com/release"
QCLIENT_RELEASE_URL="https://releases.quilibrium.com/qclient-release"
NODE_DIR="$HOME/ceremonyclient/node"
CLIENT_DIR="$HOME/ceremonyclient/client"
GSHEET_CONFIG_UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_gsheet_config_update.sh"
# Get current node version
current_node_binary=$(find "$NODE_DIR" -name "node-[0-9]*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
if [ -n "$current_node_binary" ]; then
    CURRENT_NODE_VERSION=$(basename "$current_node_binary" | grep -o '[0-9]\+\.[0-9]\+\(\.[0-9]\+\)*' || echo "")
fi

# Check if the service file exists
# if [ ! -f "$SERVICE_FILE" ]; then
#     echo "❌ Error: you are not running your node via service file:  $SERVICE_FILE"
#     echo "This update script won't work for you. Exiting."
#     exit 1
# fi

#==========================
# UTILITY FUNCTIONS
#==========================

# Function to display section headers
display_header() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
    echo
}


# The cleanup function
cleanup_old_releases() {
    local directory=$1
    local prefix=$2
    
    echo "⏳ Cleaning up old $prefix releases in $directory..."
    
    # Find the latest executable binary (will be the one we want to keep)
    local current_binary=$(find "$directory" -name "${prefix}-[0-9]*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
    
    if [ -z "$current_binary" ]; then
        echo "❌ No current $prefix binary found"
        return 1
    fi
    
    # Get just the filename without the path
    current_binary=$(basename "$current_binary")
    echo "Current binary: $current_binary"
    
    # Find and delete old files in one go - simpler approach
    find "$directory" -type f -name "${prefix}-[0-9.]*-${release_os}-${release_arch}*" ! -name "${current_binary}*" -delete
    
    echo "✅ Cleanup completed for $prefix"
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

display_header "CHECK NEEDED UPDATES"

# Determine node latest version
# Check if NODE_VERSION is empty
if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION=$(curl -s "$NODE_RELEASE_URL" | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)
    if [ -z "$NODE_VERSION" ]; then
        echo "❌ Error: Unable to determine the latest node release automatically."
        echo "The script cannot proceed without a correct node version number."
        echo
        echo "This could be caused by your provider blocking access to quilibrium.com"
        echo "A solution could be to change your machine DNS and try again the update script."
        echo "You can change your machine DNS with the command below:"
        echo "sudo sh -c 'echo "nameserver 8.8.8.8" | tee /etc/systemd/resolved.conf.d/dns_servers.conf > /dev/null && systemctl restart systemd-resolved'"
        echo
        echo "Or, you can try the manual step by step installation instead:"
        echo "https://docs.quilibrium.one/start/tutorials/node-step-by-step-installation"
        echo
        exit 1
    else
        echo "✅ Latest Node release: $NODE_VERSION"
    fi
else
    echo "✅ Using specified Node version: $NODE_VERSION"
fi

# Determine qclient latest version
# Check if QCLIENT_VERSION is empty
if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(curl -s "$QCLIENT_RELEASE_URL" | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
    if [ -z "$QCLIENT_VERSION" ]; then
        echo "⚠️ Warning: Unable to determinethe latest Qclient release automatically. Continuing without it."
        echo "The script won't be able to install the Qclient, but it will still install your node."
        echo "You can install the Qclient later manually if you need to."
        echo
        sleep 1
    else
        echo "✅ Latest Qclient release: $QCLIENT_VERSION"
    fi
else
    echo "✅ Using specified Qclient version: $QCLIENT_VERSION"
fi

# Detect OS and architecture in a unified way
case "$OSTYPE" in
    "linux-gnu"*)
        release_os="linux"
        case "$(uname -m)" in
            "x86_64") release_arch="amd64" ;;
            "aarch64") release_arch="arm64" ;;
            *) echo "❌ Error: Unsupported system architecture ($(uname -m))"; exit 1 ;;
        esac ;;
    "darwin"*)
        release_os="darwin"
        case "$(uname -m)" in
            "x86_64") release_arch="amd64" ;;
            "arm64") release_arch="arm64" ;;
            *) echo "❌ Error: Unsupported system architecture ($(uname -m))"; exit 1 ;;
        esac ;;
    *) echo "❌ Error: Unsupported operating system ($OSTYPE)"; exit 1 ;;
esac

# Set binary names based on detected OS and architecture
NODE_BINARY="node-$NODE_VERSION-$release_os-$release_arch"
GO_BINARY="go$GO_VERSION.$release_os-$release_arch.tar.gz"
QCLIENT_BINARY="qclient-$QCLIENT_VERSION-$release_os-$release_arch"

echo

#==========================
# CHECK IF UPDATE IS NEEDED
#==========================

# Function to check if a file exists and is executable
check_executable() {
    [ -x "$1" ]
}

# Set the full paths for the binary files
NODE_BINARY_PATH="$HOME/ceremonyclient/node/$NODE_BINARY"
QCLIENT_BINARY_PATH="$HOME/ceremonyclient/client/$QCLIENT_BINARY"

# Initialize flags
NODE_NEEDS_UPDATE=true
QCLIENT_NEEDS_UPDATE=true

# Check node binary
if check_executable "$NODE_BINARY_PATH"; then
    echo "🟢 Node is already updated to $NODE_VERSION"
    NODE_NEEDS_UPDATE=false
else
    echo "🟠 Node needs to be updated to $NODE_VERSION"
fi

# Check qclient binary
if check_executable "$QCLIENT_BINARY_PATH"; then
    echo "🟢 Qclient is already updated to $QCLIENT_VERSION"
    QCLIENT_NEEDS_UPDATE=false
else
    echo "🟠 Qclient needs to be updated to $QCLIENT_VERSION"
fi

echo

# Determine which parts of the script to run
if [ "$NODE_NEEDS_UPDATE" = false ] && [ "$QCLIENT_NEEDS_UPDATE" = false ]; then
    echo "✅ Both Node and Qclient are already up to date!"
    echo
    echo "⚠️ If you believe you still need to update, you can use the force update script, just run:"
    echo "curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_service_update_forced.sh" | bash"
    echo
    echo "The force update script will update your node and qclient regardless of their current versions."
    exit 0
elif [ "$NODE_NEEDS_UPDATE" = false ]; then
    echo
    echo "🟠 Only the Qclient needs to be updated. Skipping node update..."
elif [ "$QCLIENT_NEEDS_UPDATE" = false ]; then
    echo
    echo "🟠 Only the Node needs to be updated. Skipping Qclient update..."
else
    echo
    echo "✅ Both Node and Qclient need to be updated. Proceeding..."
fi



if [ "$NODE_NEEDS_UPDATE" = true ]; then

    #==========================
    # GO UPGRADE
    #==========================

    if [ "$INSTALL_GO" = true ]; then
        display_header "UPGRADING GO"

        # Check the currently installed Go version
        if go version &>/dev/null; then
            INSTALLED_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        else
            INSTALLED_VERSION="none"
        fi

        # If the installed version is not $GO_VERSION, proceed with the installation
        if [ "$INSTALLED_VERSION" != "$GO_VERSION" ]; then
            echo "⏳ Current Go version is $INSTALLED_VERSION. Proceeding with installation of Go $GO_VERSION..."

            # Download and install Go
            wget https://go.dev/dl/$GO_BINARY > /dev/null 2>&1 || echo "Failed to download Go!"
            sudo tar -xvf $GO_BINARY > /dev/null 2>&1 || echo "Failed to extract Go!"
            sudo rm -rf /usr/local/go || echo "Failed to remove existing Go!"
            sudo mv go /usr/local || echo "Failed to move Go!"
            sudo rm $GO_BINARY || echo "Failed to remove downloaded archive!"
            
            echo "✅ Go $GO_VERSION has been installed successfully."
        else
            echo "✅ Go version $GO_VERSION is already installed. No action needed."
        fi
    fi


    #==========================
    # STOP SERVICE
    #==========================

    display_header "STOPPING SERVICE"

    # Stop the ceremonyclient service if it exists
    echo "⏳ Stopping the ceremonyclient service if it exists..."
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
    # .CONFIG BACKUP
    #==========================

    display_header "CONFIG BACKUP"

    # Check if .config exists
    if [ ! -d "$NODE_DIR/.config" ]; then
        echo "⚠️ No .config directory found. Skipping backup..."
    else
        # Calculate sizes
        CONFIG_SIZE=$(du -s "$NODE_DIR/.config" | awk '{print $1}')
        FREE_SPACE=$(df -k "$NODE_DIR" | awk 'NR==2 {print $4}')
        
        # We need space for the backup plus 3x config size as free space after backup
        REQUIRED_SPACE=$((CONFIG_SIZE + (CONFIG_SIZE * 2)))

        echo "📊 Space Analysis:"
        echo "- Config Folder Size: $((CONFIG_SIZE/1024)) MB"
        echo "- Current Free Space: $((FREE_SPACE/1024)) MB"
        echo "- Required Free Space (backup + 2x .config size buffer): $((REQUIRED_SPACE/1024)) MB"

        # Check if we have enough space
        if [ $FREE_SPACE -lt $REQUIRED_SPACE ]; then
            echo "❌ Not enough free space for safe backup."
            echo "⚠️ Required: $((REQUIRED_SPACE/1024)) MB, Available: $((FREE_SPACE/1024)) MB"
            echo "⚠️ Skipping backup to prevent disk space issues..."
        else
            # Ask user with timeout
            echo
            echo "Would you like to backup your .config folder? [Y/n]"
            echo "Auto-selecting YES in 20 seconds..."
            
            read -t 20 -r REPLY
            REPLY=${REPLY:-Y}
            
            if [[ ! $REPLY =~ ^[Yy]$ ]] && [ ! -z "$REPLY" ]; then
                echo "❌ Backup skipped by user."
            else
                echo "⏳ Starting backup process..."

                # Remove any existing backup - matching any config backup with q1backup pattern
                echo "⏳ Cleaning up any existing backups..."
                find "$NODE_DIR" -maxdepth 1 -name ".config_q1backup_*" -type d -exec rm -rf {} \;

                # Create new backup with updated naming convention
                BACKUP_PATH="$NODE_DIR/.config_q1backup_${CURRENT_NODE_VERSION}"
                echo "⏳ Creating backup at: $BACKUP_PATH"
                
                if cp -r "$NODE_DIR/.config" "$BACKUP_PATH"; then
                    echo "✅ Backup completed successfully!"
                    echo "📂 Backup location: $BACKUP_PATH"
                else
                    echo "❌ Backup failed!"
                    rm -rf "$BACKUP_PATH" 2>/dev/null
                fi
            fi
        fi
    fi

    #==========================
    # CEREMONYCLIENT REPO UPDATE
    #==========================

    display_header "UPDATING CEREMONYCLIENT REPO"

    if [ "$GIT_PULL" = true ]; then

        # Set the remote URL and download
        echo "⏳ Updating ceremonyclient repo for node v$NODE_VERSION"
        cd  ~/ceremonyclient
        git remote set-url origin https://github.com/QuilibriumNetwork/ceremonyclient.git
        git checkout main
        git branch -D release
        git pull
        git checkout release
        echo "✅ Downloaded the latest changes successfully."

    else
        echo "⚠️ Repo not updated since you are running the node and qclient directly via binary files."
        echo " If you want to clone or update the repo you can do it manually later."
    fi

    #==========================
    # NODE BINARY DOWNLOAD
    #==========================

    display_header "DOWNLOADING NODE BINARY"

    # Change to the download directory
    if ! cd ~/ceremonyclient/node; then
        echo "❌ Error: Unable to change to the node directory"
        exit 1
    fi

    # Fetch the file list with error handling
    if ! files=$(curl -s -f --connect-timeout 10 --max-time 30 "$NODE_RELEASE_URL"); then
        echo "❌ Error: Failed to connect to $NODE_RELEASE_URL"
        echo "Please check your internet connection and try again."
        exit 1
    fi

    # Filter files for current architecture
    files=$(echo "$files" | grep "$release_os-$release_arch" || true)

    if [ -z "$files" ]; then
        echo "❌ Error: No node files found for $release_os-$release_arch"
        echo "This could be due to network issues or no releases for your architecture."
        exit 1
    fi

    # Download files
    for file in $files; do
        version=$(echo "$file" | cut -d '-' -f 2)
        if ! test -f "./$file"; then
            echo "⏳ Downloading $file..."
            if ! curl -s -f --connect-timeout 10 --max-time 300 "$QUILIBRIUM_RELEASES/$file" > "$file"; then
                echo "❌ Failed to download $file"
                rm -f "$file" # Cleanup failed download
                continue
            fi
            echo "Successfully downloaded $file"
            
            # Make binary executable if it's not a signature or digest file
            if [[ ! $file =~ \.(dgst|sig)$ ]]; then
                if ! chmod +x "$file"; then
                    echo "❌ Failed to make $file executable"
                    continue
                fi
                echo "Made $file executable"
            fi
        else
            echo "File $file already exists, skipping"
        fi
    done

    #==========================
    # CLEAN UP OLD RELEASE
    #==========================

    display_header "CLEANING UP OLD NODE RELEASES"
    cleanup_old_releases "$NODE_DIR" "node"

    #==========================
    # NODE BINARY SYMLINK
    #==========================

    display_header "UPDATING NODE BINARY SYMLINK"

    # Remove existing symlink if it exists
    if [ -L "/usr/local/bin/quilnode" ]; then
        echo "⏳ Removing existing quilnode symlink..."
        sudo rm /usr/local/bin/quilnode
    fi

    # Create new symlink
    echo "⏳ Creating quilnode symlink..."
    if sudo ln -s "$HOME/ceremonyclient/node/$NODE_BINARY" /usr/local/bin/quilnode; then
        echo "✅ Quilnode symlink updated successfully"
    else
        echo "❌ Failed to create quilnode symlink"
    fi
    echo

fi

if [ "$QCLIENT_NEEDS_UPDATE" = true ]; then

    #==========================
    # QCLIENT UPDATE
    #==========================

    display_header "UPDATING QCLIENT"

    # Change to the download directory
    if ! cd ~/ceremonyclient/client; then
        echo "❌ Error: Unable to change to the qclient directory"
        exit 1
    fi

    # Fetch the file list with error handling
    if ! files=$(curl -s -f --connect-timeout 10 --max-time 30 "$QCLIENT_RELEASE_URL"); then
        echo "❌ Error: Failed to connect to $QCLIENT_RELEASE_URL"
        echo "Please check your internet connection and try again."
        exit 1
    fi

    # Filter files for current architecture
    files=$(echo "$files" | grep "$release_os-$release_arch" || true)

    if [ -z "$files" ]; then
        echo "❌ Error: No qclient files found for $release_os-$release_arch"
        echo "This could be due to network issues or no releases for your architecture."
        exit 1
    fi

    # Download files
    for file in $files; do
        version=$(echo "$file" | cut -d '-' -f 2)
        if ! test -f "./$file"; then
            echo "⏳ Downloading $file..."
            if ! curl -s -f --connect-timeout 10 --max-time 300 "$QUILIBRIUM_RELEASES/$file" > "$file"; then
                echo "❌ Failed to download $file"
                rm -f "$file" # Cleanup failed download
                continue
            fi
            echo "Successfully downloaded $file"
            
            # Make binary executable if it's not a signature or digest file
            if [[ ! $file =~ \.(dgst|sig)$ ]]; then
                if ! chmod +x "$file"; then
                    echo "❌ Failed to make $file executable"
                    continue
                fi
                echo "Made $file executable"
            fi
        else
            echo "File $file already exists, skipping"
        fi
    done
    
    display_header "CLEANING UP OLD QCLIENT RELEASES"
    cleanup_old_releases "$CLIENT_DIR" "qclient"

    #==========================
    # QCLIENT BINARY SYMLINK
    #==========================

    display_header "UPDATING QCLIENT BINARY SYMLINK"

    # Remove existing symlink if it exists
    if [ -L "/usr/local/bin/qclient" ]; then
        echo "⏳ Removing existing qclient symlink..."
        sudo rm /usr/local/bin/qclient
    fi

    # Create new symlink
    echo "⏳ Creating qclient symlink..."
    if sudo ln -s "$HOME/ceremonyclient/client/$QCLIENT_BINARY" /usr/local/bin/qclient; then
        echo "✅ Qclient symlink updated successfully"
    else
        echo "❌ Failed to create qclient symlink"
    fi
    echo

fi


if [ "$NODE_NEEDS_UPDATE" = true ]; then

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
    
    if grep -q "^$key=$value$" "$file"; then
        # If the key exists with exactly the same value, do nothing
        return
    elif grep -q "^$key=" "$file"; then
        # If the key exists but with different value, update it
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
TimeoutStopSec=30s

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

fi


#==========================
# CONFIG FILE UPDATE for "REWARDS TO GOOGLE SHEET SCRIPT"
#==========================

PARENT_SCRIPT=1

curl -sSL "$GSHEET_CONFIG_UPDATE_SCRIPT_URL" | bash || true

#==========================
# START NODE VIA SERVICE
#==========================

display_header "STARTING NODE"

echo "✅ Starting Ceremonyclient Service"
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo systemctl start ceremonyclient

# Showing the node version and logs
echo "🌟Your node is now updated to v$NODE_VERSION !"
echo
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo
echo
sleep 2
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat