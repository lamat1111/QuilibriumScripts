#!/bin/bash

# Function to check if wget is installed, and install it if it is not
check_wget() {
    if ! command -v wget &> /dev/null; then
        echo "❌ wget is not installed."
	sleep 1
        echo "⌛️ Installing wget... "
	sleep 1
        sudo apt-get update && sudo apt-get install -y wget

        # Verify that wget was successfully installed
        if ! command -v wget &> /dev/null; then
            echo "❌ Failed to install wget. Please install wget manually and try again."
	    sleep 1
            exit 1
        fi
    fi
}

# Function to check if the qone.sh setup section is present in .bashrc
if ! grep -Fxq "# === qone.sh setup ===" ~/.bashrc; then
    # Run the setup script
    echo "⌛️ Upgrading the qone.sh script... just one minute!"
    sleep 3
    echo "ℹ️ Downloading qone_setup.sh..."
    if ! wget -qO- https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone_setup.sh | bash; then
        echo "❌ Error: Failed to download and execute qone-setup.sh"
        exit 1
    else
        echo "✅ qone.sh upgraded!"
	echo ""
	echo "🟢 You can now use 'Q1', 'q1', or 'qone' to launch the Node Quickstart Menu."
 	sleep 1
	echo "🟢 The menu will also load automatically every time you log in."
	echo ""
	sleep 5
        # Check if wget is installed
        check_wget
    fi
else
    echo "ℹ️ qone.sh is already upgraded."
    # Check if wget is installed
    check_wget
fi

# Function to check for updates on GitHub and download the new version if available
check_for_updates() {
    # Check if the script has just restarted after an update using a temporary file marker
    if [ -f /tmp/qone_script_updated ]; then
        rm /tmp/qone_script_updated
        return
    fi
    echo "⌛️   Checking for updates..."
    # URL for checking updates
    LATEST_SCRIPT_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone.sh"
    # Fetch the latest and current script versions
    latest_version=$(wget -qO- "$LATEST_SCRIPT_URL" | md5sum | awk '{print $1}')
    current_version=$(md5sum "$0" | awk '{print $1}')
    echo "Latest version: $latest_version"
    echo "Current version: $current_version"
    # Check if the latest version differs from the current one
    if [ "$latest_version" != "$current_version" ]; then
        echo "⌛️   A new version is available. Updating..."
        sleep 1

        # Download the latest version
        wget -q -O "$0.tmp" "$LATEST_SCRIPT_URL"

        # Verify the download succeeded
        if [ $? -eq 0 ]; then
            chmod +x "$0.tmp"
            mv -f "$0.tmp" "$0"
            touch /tmp/qone_script_updated
            echo "✅ Update complete. Restarting..."
            exec "$0"  # Restart the script with the updated version
        else
            echo "❌ Failed to download the latest version. Check your connection."
            rm -f "$0.tmp"
            exit 1
        fi
    else
        echo "✅ You already have the latest version."
    fi
}

# Run the update check function
#check_for_updates

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# User working folder
USER_HOME=$(eval echo ~$USER)

#Node path
NODE_PATH="$HOME/ceremonyclient/node"

# Version number
VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")
#VERSION="1.4.19"

# Get the system architecture
ARCH=$(uname -m)
OS=$(uname -s)

if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-amd64"
        GO_BINARY="go1.20.14.linux-amd64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-amd64"
        GO_BINARY="go1.20.14.linux-amd64.tar.gz"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$VERSION-linux-arm64"
        GO_BINARY="go1.20.14.linux-arm64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$VERSION-darwin-arm64"
        GO_BINARY="go1.20.14.linux-arm64.tar.gz"
    fi
fi

#=====================
# Function Definitions
#=====================

# URLs for scripts
UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
PREREQUISITES_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/server_setup.sh"
NODE_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_installer.sh"
GRPCURL_CONFIG_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_gRPC_calls_setup.sh"
NODE_UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
PEER_MANIFEST_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_peermanifest_checker.sh"
CHECK_VISIBILITY_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/tools/qnode_visibility_check.sh"
SYSTEM_CLEANER_URL="https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/tools/qnode_system_cleanup.sh"
TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

# Function definitions
best_providers() {
    wrap_text "$best_providers_message"
    echo ""
    echo "-------------------------------"
    read -n 1 -s -r -p "✅  Press any key to continue..."  # Pause and wait for user input
}

install_prerequisites() {
    echo ""
    echo "⌛️  Preparing server with necessary apps and settings..."
    wget --no-cache -O - "$PREREQUISITES_URL" | bash
    prompt_return_to_menu
}

install_node() {
    echo ""
    echo "⌛️  Installing node..."
    wget --no-cache -O - "$NODE_INSTALL_URL" | bash
    prompt_return_to_menu
}

configure_grpcurl() {
    echo ""
    echo "⌛️  Setting up gRPCurl..."
    wget --no-cache -O - "$GRPCURL_CONFIG_URL" | bash
    prompt_return_to_menu
}

update_node() {
    echo ""
    echo "⌛️  Updating node..."
    wget --no-cache -O - "$UPDATE_URL" | bash
    prompt_return_to_menu
}

check_visibility() {
    echo ""
    echo "⌛️  Checking node visibility..."
    wget -O - "$CHECK_VISIBILITY_URL" | bash
    prompt_return_to_menu
}

system_cleaner() {
    echo ""
    echo "⌛️  Cleaning your system..."
    wget -O - "$SYSTEM_CLEANER_URL" | bash
    prompt_return_to_menu
}

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        read -n 1 -s -r -p "✅  Press any key to continue..."
        echo ""  # Add an empty line for better readability
    else
        echo ""
	echo "⌛️  Displaying node info..."
	echo ""
    	sleep 1
        cd ~/ceremonyclient/node && ./$NODE_BINARY -node-info
	echo ""
	read -n 1 -s -r -p "✅  Press any key to continue..."  # Pause and wait for user input
    fi
}

quil_balance() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    else
        echo ""
        echo "⌛️  Displaying your QUIL balance..."
	echo ""
    	sleep 1
        cd ~/ceremonyclient/node && ./$NODE_BINARY -balance
	echo ""
	read -n 1 -s -r -p "✅  Press any key to continue..."  # Pause and wait for user input
    fi
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        read -n 1 -s -r -p "✅  Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo ""
    echo "⌛️  Displaying your node log...  (Press CTRL+C to return to the main menu)"
    echo ""
    trap 'echo "Returning to main menu..."; return_to_menu' INT  # Trap CTRL+C to return to main menu
    sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
}

return_to_menu() {
    clear
    display_menu
}

restart_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
		read -n 1 -s -r -p "✅  Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo ""
    echo "⌛️   Restarting node service..."
    echo ""
    sleep 1
    service ceremonyclient restart
    sleep 5
    echo "✅   Node restarted"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."  # Pause and wait for user input
}

stop_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
	read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo ""
    echo "⌛️  Stopping node service..."
    echo ""
    sleep 1
    service ceremonyclient stop
    sleep 3
    echo "✅   Node stopped"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."  # Pause and wait for user input
}

peer_manifest() {
    echo "⌛️  Checking peer manifest (Difficulty metric)..."
    wget --no-cache -O - "$PEER_MANIFEST_URL" | bash
    prompt_return_to_menu
}

node_version() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
		read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo ""
    echo "⌛️   Displaying node version..."
    echo ""
    sleep 1
    journalctl -u ceremonyclient -r --no-hostname  -n 1 -g "Quilibrium Node" -o cat
    echo ""
    read -n 1 -s -r -p "✅ Press any key to continue..."  # Pause and wait for user input
}

help_message() {
    echo "$help_message"
    echo ""
    prompt_return_to_menu
}


test_script() {
echo "⌛️   Running test script..."
    wget --no-cache -O - "$TEST_URL" | bash
}



# Function to prompt for returning to the main menu
prompt_return_to_menu() {
    echo -e "\n\n"  # Add two empty lines for readability
    echo "---------------------------------------------"
    read -rp "⬅️   Go back to the main menu? (y/n): " return_to_menu
    case $return_to_menu in
        [Yy]) return 0 ;;  # Return to the main menu
        *) 
            echo "Exiting the script..."
            exit 0
            ;;
    esac
}

confirm_action() {
    cat << EOF

$1

✅ Do you want to proceed with "$2"? (y/n):
EOF
    read -p "> " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if $3; then
            if [ $? -eq 0 ]; then  # Check if action returns success
                prompt_return_to_menu
            fi
        else
            echo "❌ Action \"$2\" failed."
        fi
        return 0
    else
        echo "❌ Action \"$2\" canceled."
        return 1
    fi
}


# Function to wrap and indent text
wrap_text() {
    local text="$1"
    local indent="$2"
    echo "$text" | fold -s -w 80 | awk -v indent="$indent" '{printf "%s%s\n", indent, $0}'
}

wrap_text_2() {
    local text="$1"
    echo "$text" | fold -s -w 100
}

#=====================
# Message Definitions
#=====================

# Define messages
best_providers_message='
Check out the best server providers for your node
at ⭐️ https://iri.quest/q-best-providers ⭐️

Avoid using providers that specifically ban crypto and mining.
'

prepare_server_message='
This action will install the necessary prerequisites for your server. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/
'

install_node_message='
This action will install the node on your server. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/ 
Ensure that your server meets all the requirements and that you have 
already prepared you server via Step 1.
'

update_node_message='
This action will update your node. 
Only use this if you have installed the node via the guide at 
https://docs.quilibrium.one/
'

setup_grpcurl_message='
This action will make some edit to your config.yml to enable communication with the network. 
If this a fresh node installation, let the node run for 30 minutes before doing this.
'

peer_manifest_message='
This action will check the peer manifest to provide information about the difficulty metric score of your node. 
It only works after 15-30 minutes that the node has been running.
'

test_script_message='
This will run the test script.
'

help_message='
Here are all the options of the Quickstart Node Menu
====================================================

 0) Best server providers:
    Check out the best server providers for your node
    at ⭐️ https://iri.quest/q-best-providers ⭐️
    Avoid using providers that specifically ban crypto and mining.

 1) Prepare your server:
    This action will install the necessary prerequisites for your server. 
    If this is the first time you install a Quilibrium node, it is recommended
    to follow the online guide at: https://docs.quilibrium.one/

 2) Install node:
    This action will install the node on your server. 
    If this is the first time you install a Quilibrium node, it is recommended
    to follow the online guide at: https://docs.quilibrium.one/ 
    Ensure that your server meets all the requirements and that you have 
    already prepared your server via Step 1.

 3) Set up gRPCurl:
    This action will make some edits to your config.yml to enable communication with the network. 
    If this is a fresh node installation, let the node run for 30 minutes before doing this.

 4) Node Log:
    Display the log of the node.

 5) Update node:
    This action will update your node. 
    Only use this if you have installed the node via the guide at 
    https://docs.quilibrium.one/

 6) Stop node:
    Stop the node.

 7) Restart node:
    Restart the node.

 8) Node version:
    Display the version of the node.

 9) Node info (peerID & balance):
    Display information about your node peerID and balance.

10) QUIL balance:
    Display the balance of QUIL tokens.

11) Peer manifest (Difficulty metric):
    Check the peer manifest to provide information about the difficulty metric score of your node. 
    It only works after the node has been running for 15-30 minutes.

12) Check visibility:
    Check the visibility status of the node.

13) System cleaner:
    Perform system cleanup tasks. It will not affect your node.
'

#=====================
# Main Menu Function
#=====================

display_menu() {
    clear
    source ~/.bashrc
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
                      ✨ QNODE QUICKSTART ✨
===================================================================
         Follow the guide at https://docs.quilibrium.one

                      Made with 🔥 by LaMat
====================================================================

EOF

    cat << "EOF"
If you want to install a new node, choose option 1, and then 2

------------------------------------------------------------------
0) Best server providers      8) Node version
1) Prepare your server        9) Node info (peerID & balance)    
2) Install node              10) QUIL balance
3) Set up gRPCurl            11) Peer manifest (Difficulty metric)
4) Node Log                  12) Check visibility
5) Update node               13) System cleaner
6) Stop node
7) Restart node
------------------------------------------------------------------
E) Exit                       H) Help

EOF
}

#20) Test Script

#=====================
# Main Menu Loop
#=====================

while true; do
    display_menu
    
    read -rp "Enter your choice: " choice
    action_performed=0
    
    case $choice in
    	0) best_providers;;
        1) confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites;;
        2) confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node;;
	3) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPCurl" configure_grpcurl;;
        4) node_logs action_performed=1;;
        5) confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node;;
	6) stop_node action_performed=1;;
        7) restart_node action_performed=1;;
	8) node_version action_performed=1;;
        9) node_info action_performed=1;;
 	10) quil_balance action_performed=1;;
        11) confirm_action "$(wrap_text "$peer_manifest_message" "")" "Peer manifest" peer_manifest;;
        12) check_visibility;;
	13) system_cleaner;;
	20) confirm_action "$(wrap_text "$test_script_message" "")" "Test Script" test_script;;
        [eE]) exit ;;
	[hH]) help_message;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    if [ $action_performed -eq 1 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
    fi
done

