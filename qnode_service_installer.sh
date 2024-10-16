#!/bin/bash

# Step 0: Welcome

#Node version is not used - executiu via release_autorun 
#Comment out for automatic creation of the node version
#NODE_VERSION=2.0

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=1.4.19.1

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
                              
===================================================================
                 ✨ QNODE SERVICE INSTALLER ✨
===================================================================
This script will install your Quilibrum node as a service.
It will run your node from the binary file, and you will have to
update manually.

Be sure to run the 'Server Setup' script first.
Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

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

display_header "CREATING PATH VARIABLES"

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)


# ONLY NECESSARY IF RUNNING THE NODE VIA BINARY IN THE SERVICE
# Determine node latest version
# Check if NODE_VERSION is empty
if [ -z "$NODE_VERSION" ]; then
    NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)
    if [ -z "$NODE_VERSION" ]; then
        echo "❌ Error: Unable to determine NODE_VERSION automatically."
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

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
        #GO_BINARY="go1.22.4.linux-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
        #GO_BINARY="go1.22.4.darwin-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
        #GO_BINARY="go1.22.4.linux-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
        #GO_BINARY="go1.22.4.darwin-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi

#==========================
# CEREMONYCLIENT REPO UPDATE
#==========================

display_header "UPDATING CEREMONYCLIENT REPO"

# Download Ceremonyclient
echo "⏳ Downloading Ceremonyclient..."
sleep 1  # Add a 1-second delay
cd ~
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

# Set up environment variables (redundant but solves the command go not found error)
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#==========================
# NODE BINARY DOWNLOAD
#==========================

display_header "DOWNLOADING NODE BINARY"

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

# Base URL for the Quilibrium releases
RELEASE_FILES_URL="https://releases.quilibrium.com/release"

# Fetch the list of files from the release page
# Updated regex to allow for an optional fourth version number
RELEASE_FILES=$(curl -s $RELEASE_FILES_URL | grep -oE "node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Change to the download directory
cd ~/ceremonyclient/node

# Download each file
for file in $RELEASE_FILES; do
    echo "Downloading $file..."
    if curl -L -o "$file" "https://releases.quilibrium.com/$file" --fail --silent; then
        echo "✅ Successfully downloaded $file"
        # Check if the file is the base binary (without .dgst or .sig suffix)
        if [[ $file =~ ^node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}$ ]]; then
            if chmod +x "$file"; then
                echo "✅ Made $file executable"
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
# DOWNLOAD QCLIENT
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
        echo "✅ Successfully downloaded $filename"
        return 0
    else
        return 1
    fi
}

# Download the main binary
echo "Downloading $QCLIENT_BINARY..."
if download_and_overwrite "$BASE_URL/$QCLIENT_BINARY" "$QCLIENT_BINARY"; then
    chmod +x $QCLIENT_BINARY
    # Rename the binary to qclient, overwriting if it exists
    #mv -f "$QCLIENT_BINARY" qclient
    #chmod +x qclient
    #echo "✅ Renamed to qclient and made executable"
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
# SETUP SERVICE
#==========================

display_header "CREATING SERVICE FILE"

# Get the current user's home directory
HOME=$(eval echo ~$USER)

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

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START
ExecStop=/bin/kill -s SIGINT \$MAINPID
KillSignal=SIGINT
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
