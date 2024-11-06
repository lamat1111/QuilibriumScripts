#!/bin/bash

# Step 0: Welcome

#Comment out for automatic creation of the node version
#NODE_VERSION=2.0.3

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=2.0.2.4

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
                   ✨ QNODE / QCLIENT INSTALLER ✨
===========================================================================
This script will install your Quilibrum node as a service.
It will run your node from the binary file, and you will have to
update manually.

Be sure to run the 'Server Setup' script first.
Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 7  # Add a 7-second delay

# Function to display section headers
display_header() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
    echo
}


GIT_CLONE=false

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
# INSTALL APPS
#==========================

display_header "INSTALLING REQUIRED APPLICATIONS"

# Function to check and install a package
check_and_install() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        echo "⏳ Installing $1..."
        sudo apt install $1 -y
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
# DOWNLOAD QCLIENT
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


#==========================
# SETUP SERVICE
#==========================

display_header "CREATING SERVICE FILE"

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/$NODE_BINARY"

# Step 6: Create Ceremonyclient Service
echo "⏳ Creating Ceremonyclient Service"
sleep 1

# Calculate GOMAXPROCS based on the system's RAM and CPU cores
calculate_gomaxprocs() {
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local cpu_cores=$(nproc)
    
    # Check if RAM is at least double the number of CPU cores
    if [ $ram_gb -ge $((cpu_cores * 2)) ]; then
        echo "0"  # GOMAXPROCS not needed
    else
        local gomaxprocs=$((ram_gb / 2))
        if [ $gomaxprocs -gt $cpu_cores ]; then
            gomaxprocs=$cpu_cores
        fi
        gomaxprocs=$((gomaxprocs + 1))
        echo $gomaxprocs
    fi
}

GOMAXPROCS=$(calculate_gomaxprocs)

if [ "$GOMAXPROCS" -eq "0" ]; then
    echo "✅ RAM is sufficient (at least double the CPU cores). GOMAXPROCS setting is not needed."
else
    echo "✅ GOMAXPROCS has been set to $GOMAXPROCS based on your server's resources."
fi
echo

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
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
ExecStop=/bin/kill -s SIGINT \$MAINPID
KillSignal=SIGINT
RestartKillSignal=SIGINT
FinalKillSignal=SIGKILL
TimeoutStopSec=30s"

# Add GOMAXPROCS to the service file only if needed
if [ "$GOMAXPROCS" -ne "0" ]; then
    SERVICE_CONTENT+="
Environment=\"GOMAXPROCS=$GOMAXPROCS\""
fi

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
sleep 1

#==========================
# START NODE VIA SERVICE
#==========================

display_header "STARTING NODE"

# Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
echo

sleep 2  # Add a 2-second delay
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo systemctl start ceremonyclient

# Final messages
echo "✅ Now your node is starting!"
echo "Let it run for at least 15-30 minutes to generate your keys."
echo
echo "✅ You can logout of your server if you want and login again later."
echo
echo "After 30 minutes, backup your keys.yml and config.yml files."
echo "Then proceed to set up your gRPC calls,"
echo "and lastly set up an automatic backup for your .config folder."
echo
echo "More info about all this in the online guide: https://docs.quilibrium.one"
echo
echo "⏳ Now I will show the node log below..."
echo "To exit the log, just type CTRL +C."
echo
# See the logs of the ceremonyclient service
sleep 3  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
