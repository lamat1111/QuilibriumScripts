#!/bin/bash

# Step 0: Welcome

#Comment out for automatic creation of the node version
#NODE_VERSION=2.0.4

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=2.0.3

SCRIPT_VERSION="2.6"

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
                 ✨ QNODE / QCLIENT INSTALLER - $SCRIPT_VERSION ✨
===========================================================================
This script will install your Quilibrum node as a service.
It will run your node from the binary file, and you will have to
update manually.

Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 7  # Add a 7-second delay

GIT_CLONE=false

# Add version check and warning at start
check_existing_installation() {
    if systemctl is-active --quiet ceremonyclient; then
        echo "⚠️  WARNING: Seems like you already have a node installed!"
        read -p "Do you want to proceed with reinstallation? (y/n): " proceed
        if [[ $proceed != "y" && $proceed != "Y" ]]; then
            exit 0
        fi
    fi
}

check_existing_installation

# Function to display section headers
display_header() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
    echo
}


#==========================
# MANAGE ERRORS
#==========================

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

#==========================
# HOSTNAME CONFIGURATION
#==========================

display_header "CONFIGURING HOSTNAME"

# Display current hostname
current_hostname=$(hostname)
echo "Current hostname is: $current_hostname"

# Ask if user wants to change the hostname
read -p "Do you want to change it? (y/n): " answer

# Temporarily disable exit on error for this section
set +e

if [[ $answer == "y" || $answer == "Y" ]]; then
    read -p "Enter new hostname: " new_hostname
    sudo hostnamectl set-hostname "$new_hostname"
    echo "✅ Hostname changed to: $new_hostname"
else
    echo "✅ Hostname not changed."
fi
echo

# Re-enable exit on error for the rest of the script
set -e

#==========================
# INSTALL APPS
#==========================

display_header "INSTALLING REQUIRED APPLICATIONS"

# Function to check and install a package with better error handling
check_and_install() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        echo "⏳ Installing $1..."
        if ! sudo apt install $1 -y; then
            echo "⚠️ Failed to install $1"
            return 1
        fi
    else
        echo "$1 is installed"
    fi
}

# Update and Upgrade the Machine
echo "⏳ Updating the machine..."
sleep 2
if ! sudo apt update -y; then
    echo "⚠️ Warning: apt update failed, continuing..."
fi
if ! sudo apt upgrade -y; then
    echo "⚠️ Warning: apt upgrade failed, continuing..."
fi
echo "✅ Machine updated."
echo

# Install required packages
echo "⏳ Installing required packages: sudo, git, wget, tar, curl..."
for pkg in sudo git wget tar curl; do
    check_and_install "$pkg" || { 
        echo "❌ These are necessary apps, installation failed..."
        exit_message
        exit 1
    }
done
echo "✅ Required packages installed successfully."
echo

# Install optional packages
echo "⏳ Installing optional packages: tmux, cron, jq, htop..."
# Temporarily disable exit on error for optional packages
set +e
for pkg in tmux cron jq htop; do
    if ! check_and_install "$pkg"; then
        echo "⚠️ Optional package $pkg installation failed, continuing..."
    fi
done
# Re-enable exit on error
set -e
echo "✅ Optional packages installation completed."
echo

#==========================
# NETWORK CONFIGURATION
#==========================

display_header "CONFIGURING NETWORK SETTINGS"

echo "⏳ Adjusting network buffer sizes..."

# Load OS release information including VERSION_ID
if [ -f /etc/os-release ]; then
    . /etc/os-release  # This loads VERSION_ID, NAME, and other OS variables
fi

add_sysctl_setting() {
    local key=$1
    local value=$2
    # Remove existing entry if present
    sudo sed -i "/^${key}=/d" /etc/sysctl.conf
    # Add new entry
    echo "${key}=${value}" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "✅ Added ${key}=${value}"
}

# Temporarily disable exit on error for this section
set +e

add_sysctl_setting "net.core.rmem_max" "600000000"
add_sysctl_setting "net.core.wmem_max" "600000000"

# Use VERSION_ID from os-release to determine sysctl command
if [[ "${VERSION_ID}" == "24.04" ]]; then
    sudo /sbin/sysctl -p/etc/sysctl.conf
else
    sudo sysctl -p
fi

sudo /etc/init.d/procps restart
echo "✅ Network buffer sizes updated"
echo

# Re-enable exit on error for the rest of the script
set -e

#==========================
# SECURITY CONFIGURATION
#==========================

display_header "CONFIGURING SECURITY SETTINGS"

# Temporarily disable exit on error for this section
set +e

# Add UFW rule deduplication
ufw_add_unique() {
    local port=$1
    if ! sudo ufw status | grep -q "^$port"; then
        sudo ufw allow $port
    fi
}

# UFW Firewall Setup
# UFW Firewall Setup
echo "⏳ Setting up UFW firewall..."
sudo apt install ufw -y || echo "⚠️ Failed to install UFW"

if command -v ufw >/dev/null 2>&1 && sudo ufw status >/dev/null 2>&1; then
    echo "y" | sudo ufw enable
    for port in 22 8336 443; do
        ufw_add_unique $port
    done
    sudo ufw status
    echo "✅ Firewall configured"
else
    echo "⚠️ UFW installation failed. Manual configuration required."
fi
echo

# Fail2Ban Setup
echo "⏳ Setting up Fail2Ban..."

if ! dpkg -s fail2ban &> /dev/null; then
    sudo apt install fail2ban -y
fi

if [ ! -f "/etc/fail2ban/jail.d/sshd.conf" ]; then
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.backup
    cat << EOF | sudo tee /etc/fail2ban/jail.d/sshd.conf > /dev/null
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
findtime = 300
bantime = 1800
EOF
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    echo "✅ Fail2Ban configured"
fi
echo

# Re-enable exit on error for the rest of the script
set -e

sleep 3

#==========================
# DIRECTORY SETUP
#==========================

display_header "SETTING UP DIRECTORIES"

echo "⏳ Creating utility directories..."
sudo mkdir -p /root/{backup,scripts,scripts/log}
echo "✅ Directories created"
echo

#==========================
# CREATE PATH VARIABLES
#==========================

display_header "CREATING PATH VARIABLES"

#useful variables
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
QUILIBRIUM_RELEASES="https://releases.quilibrium.com"
NODE_RELEASE_URL="https://releases.quilibrium.com/release"
QCLIENT_RELEASE_URL="https://releases.quilibrium.com/qclient-release"

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
        echo "You can try to change your machine DNS with the command below:"
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
        echo "⚠️ Warning: Unable to determine the latest Qclient release automatically. Continuing without it."
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
QCLIENT_BINARY="qclient-$QCLIENT_VERSION-$release_os-$release_arch"

echo

#==========================
# GIT CLONE
#==========================

if [ "$GIT_CLONE" = true ]; then

    display_header "UPDATING CEREMONYCLIENT REPO"

    # Download Ceremonyclient
    echo "⏳ Downloading Ceremonyclient..."
    sleep 1  # Add a 1-second delay
    cd $HOME
    if [ -d "ceremonyclient" ]; then
        echo "⚠️ Looks like you already have a node installed!"
        echo "The directory 'ceremonyclient' already exists. Skipping git clone..."
        echo
        else
        until git clone --depth 1 --branch release https://github.com/QuilibriumNetwork/ceremonyclient.git || git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git; do
            echo "Git clone failed, retrying..."
            sleep 2
        done
    fi
    echo
fi

#==========================
# NODE BINARY DOWNLOAD
#==========================

display_header "DOWNLOADING NODE BINARY"

if [ "$GIT_CLONE" = false ]; then

    # Create directories if they don't exist
    mkdir -p "$HOME/ceremonyclient"
    mkdir -p "$HOME/ceremonyclient/node"
    mkdir -p "$HOME/ceremonyclient/client"

    echo "Directories created successfully."
fi

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
# NODE BINARY SYMLINK
#==========================

display_header "CREATING NODE BINARY SYMLINK"

# Remove existing symlink if it exists
if [ -L "/usr/local/bin/quilnode" ]; then
    echo "⏳ Updating existing quilnode symlink..."
    sudo rm /usr/local/bin/quilnode
fi

# Create new symlink
echo "⏳ Creating quilnode symlink..."
if sudo ln -s "$HOME/ceremonyclient/node/$NODE_BINARY" /usr/local/bin/quilnode; then
    echo "✅ Quilnode symlink created successfully"
else
    echo "❌ Failed to create quilnode symlink"
fi
echo

sleep 3

#==========================
# DOWNLOAD QCLIENT
#==========================

display_header "UPDATING QCLIENT"

# Temporarily disable exit on error for optional packages
set +e

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

# Re-enable exit on error for optional packages
set -e

#==========================
# QCLIENT BINARY SYMLINK
#==========================

display_header "CREATING QCLIENT BINARY SYMLINK"

# Remove existing symlink if it exists
if [ -L "/usr/local/bin/qclient" ]; then
    echo "⏳ Updating existing qclient symlink..."
    sudo rm /usr/local/bin/qclient
fi

# Create new symlink
echo "⏳ Creating qclient symlink..."
if sudo ln -s "$HOME/ceremonyclient/client/$QCLIENT_BINARY" /usr/local/bin/qclient; then
    echo "✅ Qclient symlink created successfully"
else
    echo "❌ Failed to create qclient symlink"
fi
echo

sleep 3

#==========================
# SETUP SERVICE
#==========================

display_header "CREATING SERVICE FILE"

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/$NODE_BINARY"

# Step 6: Create Ceremonyclient Service
echo "⏳ Creating Ceremonyclient Service"

# # Calculate GOMAXPROCS based on the system's RAM and CPU cores
# calculate_gomaxprocs() {
#     local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
#     local cpu_cores=$(nproc)
#     local original_calc=0
    
#     # Check if RAM is at least double the number of CPU cores
#     if [ $ram_gb -ge $((cpu_cores * 2)) ]; then
#         echo "0"  # GOMAXPROCS not needed
#     else
#         local gomaxprocs=$((ram_gb / 2))
#         if [ $gomaxprocs -gt $cpu_cores ]; then
#             gomaxprocs=$cpu_cores
#         fi
#         gomaxprocs=$((gomaxprocs + 1))
#         original_calc=$gomaxprocs
        
#         # Ensure GOMAXPROCS is never less than 4
#         if [ $gomaxprocs -lt 4 ]; then
#             echo "WARNING:$original_calc:4"  # Special format to handle warning
#         else
#             echo $gomaxprocs
#         fi
#     fi
# }

# GOMAXPROCS_OUTPUT=$(calculate_gomaxprocs)

# # Parse the output to handle warning case
# if [[ $GOMAXPROCS_OUTPUT == WARNING:*:* ]]; then
#     # Extract original and new values from warning output
#     ORIGINAL_CALC=$(echo $GOMAXPROCS_OUTPUT | cut -d':' -f2)
#     GOMAXPROCS=4
#     display_header "⚠️  WARNING: INSUFFICIENT RESOURCES DETECTED"
#     echo "You only have enough RAM to run ${ORIGINAL_CALC} cores, which are not sufficient for your node."
#     echo "We have still set your service to run the minimum number of cores (4),"
#     echo "but you will likely have OOM (out of memory errors) once the node begins to produce proofs."
#     echo
# elif [ "$GOMAXPROCS_OUTPUT" -eq "0" ]; then
#     GOMAXPROCS=0
#     echo "✅ RAM is sufficient (at least double the CPU cores). GOMAXPROCS setting is not needed."
# else
#     GOMAXPROCS=$GOMAXPROCS_OUTPUT
#     echo "✅ GOMAXPROCS has been set to $GOMAXPROCS based on your server's resources."
# fi
# echo

# Check if the file exists before attempting to remove it
if [ -f "/lib/systemd/system/ceremonyclient.service" ]; then
    rm /lib/systemd/system/ceremonyclient.service
    echo "ceremonyclient.service file removed."
else
    echo "ceremonyclient.service file does not exist. No action taken."
fi

# Prepare the service file content
SERVICE_CONTENT="[Unit]
Description=Ceremony Client Go App Service
StartLimitIntervalSec=0
StartLimitBurst=0

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
ExecStop=/bin/kill -s SIGINT \$MAINPID
KillSignal=SIGINT
RestartKillSignal=SIGINT
FinalKillSignal=SIGKILL
TimeoutStopSec=240s"

# # Add GOMAXPROCS to the service file only if needed
# if [ "$GOMAXPROCS" -ne "0" ]; then
#     SERVICE_CONTENT+="
# Environment=\"GOMAXPROCS=$GOMAXPROCS\""
# fi

SERVICE_CONTENT+="

[Install]
WantedBy=multi-user.target"

# Write the service file
echo "$SERVICE_CONTENT" | sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null

echo
echo "This is your current updated service file."
echo "If you notice errors please correct them manually and restart your node."
echo "------------------------------------------------"
cat /lib/systemd/system/ceremonyclient.service
echo "------------------------------------------------"
sleep 7

#==========================
# .CONFIG YML SETUP
#==========================
echo "⏳ Creating node config.yml file..."

# Disable exit on error for optional packages
set +e

cd "$HOME/ceremonyclient/node"

if ! ./"$NODE_BINARY" -peer-id; then
    echo "❌ Config.yml generation failed. No worries, the node will generate it automatically once it starts."
else
    if [ -f ".config/config.yml" ]; then
        echo "✅ Config.yml generated successfully."
        cd "$HOME/ceremonyclient/node/.config" 
        if ! sed -i 's|listenGrpcMultiaddr: ""|listenGrpcMultiaddr: "/ip4/127.0.0.1/tcp/8337"|' ./config.yml || \
           ! sed -i 's|listenRESTMultiaddr: ""|listenRESTMultiaddr: "/ip4/127.0.0.1/tcp/8338"|' ./config.yml; then
            echo "❌ Failed to update gRPC settings in config.yml. No worries, you can to do this later..."
        else
            echo "✅ gRPC settings added successfully to config.yml"
        fi
    else
        echo "❌ Config.yml not found. No worries, the node will generate it automatically once it starts."
    fi
fi

# Re-enable exit on error for optional packages
set -e

sleep 3

#==========================
# INSTALLATION COMPLETED
#==========================

display_header "✅ INSTALLATION COMPLETED"

sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient

echo "Server setup is finished!"
echo "⚠️ Your server will reboot in 20 seconds..."
echo
echo "After the reboot, your node will start automatically"
echo "After 30 minutes that your node has been running, backup your keys.yml and config.yml files."
echo "More info in the online guide: https://docs.quilibrium.one"
sleep 20
sudo reboot