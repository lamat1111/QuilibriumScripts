#!/bin/bash
# Function to check for updates on GitHub and download the new version if available
# Function to check for updates on GitHub and download the new version if available
# Function to check for updates on GitHub and download the new version if available
# Function to check for updates on GitHub and download the new version if available

# Function to check for updates on GitHub and download the new version if available
check_for_updates() {
    echo "⚙️ Checking for updates..."
    latest_version=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/testing/qone.sh | md5sum | awk '{print $1}')
    current_version=$(md5sum $0 | awk '{print $1}')

    if [ "$latest_version" != "$current_version" ]; then
        echo "⚙️ A new version is available. Updating..."
        wget -O "$0.tmp" https://github.com/lamat1111/QuilibriumScripts/raw/testing/qone.sh
        chmod +x "$0.tmp"
        mv -f "$0.tmp" "$0"
        echo "✅ Update complete. Restarting..."
        exec "$0"
    else
        echo "✅ You already have the latest version."
    fi
}

# Check for updates
check_for_updates

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
# User working folder
USER_HOME=$(eval echo ~$USER)

# Set the version number
#VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")
VERSION="1.4.18"

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
UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/testing/qone.sh"
PREREQUISITES_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/server_setup.sh"
NODE_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_installer.sh"
GRPCURL_CONFIG_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_gRPC_calls_setup.sh"
NODE_UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
PEER_MANIFEST_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/main_new/tools/qnode_peermanifest_checker.sh"
CHECK_VISIBILITY_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_visibility_check.sh"
TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

# Function definitions

best_providers() {
 "$(wrap_text "$best_providers_message" "")"
}

install_prerequisites() {
    echo "⚙️  Running installation script for server prerequisites..."
    wget --no-cache -O - "$PREREQUISITES_URL" | bash
}

install_node() {
    echo "⚙️  Running installation script for Quilibrium Node..."
    wget --no-cache -O - "$NODE_INSTALL_URL" | bash
}

configure_grpcurl() {
    echo "⚙️  Running configuration script for gRPCurl..."
    wget --no-cache -O - "$GRPCURL_CONFIG_URL" | bash
}

update_node() {
    echo "⚙️  Running update script for Quilibrium Node..."
    wget --no-cache -O - "$UPDATE_URL" | bash
}

check_visibility() {
    echo "⚙️  Checking visibility of Quilibrium Node..."
    wget -O - "$CHECK_VISIBILITY_URL" | bash
}

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    else
        echo "⚙️  Displaying information about Quilibrium Node..."
	echo ""
    	sleep 1
        cd ~/ceremonyclient/node && ./$NODE_BINARY -node-info
    fi
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
		read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo "⚙️  Displaying logs of Quilibrium Node..."
    echo ""
    sleep 1
    sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
}

restart_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
		read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo "⚙️  Restarting Quilibrium Node service..."
    echo ""
    sleep 1
    service ceremonyclient restart
    sleep 5
    echo "Node restarted"
}

stop_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
	read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo "⚙️ Stopping Quilibrium Node service..."
    echo ""
    sleep 1
    service ceremonyclient stop
    sleep 3
    echo "Node stopped"
}

peer_manifest() {
    echo "⚙️ Checking peer manifest (Difficulty metric)..."
    wget --no-cache -O - "$PEER_MANIFEST_URL" | bash
}

node_version() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
		read -n 1 -s -r -p "Press any key to continue..."
        echo ""  # Add an empty line for better readability
    fi
    echo "⚙️ Displaying Quilibrium Node version..."
    echo ""
    sleep 1
    journalctl -u ceremonyclient -r --no-hostname  -n 1 -g "Quilibrium Node" -o cat
    sleep 1
}

test_script() {
echo "⚙️ Running test script..."
    wget --no-cache -O - "$TEST_URL" | bash
}



# Function to prompt for returning to the main menu
prompt_return_to_menu() {
    echo -e "\n\n"  # Add two empty lines for readability
    echo "---------------------------------------------------"
    read -rp "⬅️   Go back to the main menu? Type Y or N: " return_to_menu
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

Do you want to proceed with "$2"? Type Y or N:
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

#=====================
# Message Definitions
#=====================

# Define messages
best_providers_message='
Check out the best server providers for your node
at https://docs.quilibrium.one/quilibrium-node-setup-guide/best-server-providers

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
This will run the test script
'

#=====================
# Main Menu Function
#=====================

display_menu() {
    clear
    cat << EOF

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

    echo -e "Choose an option:\n"
    echo "If you want to install a new node, choose option 1, and then 2"
    echo ""
    echo "0) Best server providers"
    echo "------------------------"
    echo "1) Prepare your server"
    echo "2) Install Node"
    echo "------------------------"
    echo "3) Update Node"
    echo "4) Set up gRPCurl"
    echo "5) Check Visibility"
    echo "6) Node Info"
    echo "7) Node Logs (CTRL+C to detach)"
    echo "8) Restart Node"
    echo "9) Stop Node"
    echo "10) Peer manifest (Difficulty metric)"
    echo "11) Node Version"
    #echo "12) Test Script"
    echo "------------------------"
    echo "e) Exit"
    echo ""
}

#=====================
# Main Menu Loop
#=====================

while true; do
    display_menu
    
    read -rp "Enter your choice: " choice
    action_performed=0

    case $choice in
    	0) best_providers action_performed=1 ;;
        1) confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites prompt_return_to_menu;;
        2) confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node prompt_return_to_menu;;
        3) confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node prompt_return_to_menu;;
        4) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPCurl" configure_grpcurl prompt_return_to_menu;;
        5) check_visibility prompt_return_to_menu;;
        6) node_info prompt_return_to_menu;;
        7) node_logs action_performed=1 ;;
        8) restart_node action_performed=1 ;;
        9) stop_node action_performed=1 ;;
        10) confirm_action "$(wrap_text "$peer_manifest_message" "")" "Peer manifest" peer_manifest prompt_return_to_menu;;
        11) node_version prompt_return_to_menu;;
	12) confirm_action "$(wrap_text "$test_script_message" "")" "Test Script" test_script prompt_return_to_menu;;
        e) exit ;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    if [ $action_performed -eq 1 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
    fi
done
