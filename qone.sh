#!/bin/bash

# Function to check for updates on GitHub and download the new version if available
check_for_updates() {
    echo "⚙️ Checking for updates..."
    latest_version=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/testing/qone.sh | md5sum | awk '{print $1}')
    current_version=$(md5sum $0 | awk '{print $1}')

    if [ "$latest_version" != "$current_version" ]; then
        echo "⚙️ A new version is available. Updating..."
        wget -O "$0.tmp" https://github.com/lamat1111/QuilibriumScripts/raw/main/testing/qone.sh
        chmod +x "$0.tmp"
        mv -f "$0.tmp" "$0"
        echo "✅ Update complete. Restarting..."
        exec "$0"
    else
        echo "✅ You already have the latest version."
    fi
}

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
# User working folder
HOME=$(eval echo ~$USER)
# Node path
NODE_PATH="$HOME/ceremonyclient/node" 

VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Get the system architecture
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

# Function to ask for confirmation with an EOF message
confirm_action() {
    cat << EOF

$1

Do you want to proceed with "$2"? Type Y or N:
EOF
    read -p "> " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        $3
        return 0
    else
        echo "❌ Action \"$2\" canceled."
        return 1
    fi
}

# URLs for scripts
UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/testing/qone.sh"
PREREQUISITES_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/server_setup.sh"
NODE_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_installer.sh"
GRPCURL_CONFIG_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_gRPC_calls_setup.sh"
NODE_UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
PEER_MANIFEST_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/main_new/tools/qnode_peermanifest_checker.sh"
CHECK_VISIBILITY_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_visibility_check.sh"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

# Function definitions

install_prerequisites() {
    echo "⚙️ Running installation script for server prerequisites..."
    wget --no-cache -O - "$PREREQUISITES_URL" | bash
}

install_node() {
    echo "⚙️ Running installation script for Quilibrium Node..."
    wget --no-cache -O - "$NODE_INSTALL_URL" | bash
}

configure_grpcurl() {
    echo "⚙️ Running configuration script for gRPCurl..."
    wget --no-cache -O - "$GRPCURL_CONFIG_URL" | bash
}

update_node() {
    echo "⚙️ Running update script for Quilibrium Node..."
    wget --no-cache -O - "$UPDATE_URL" | bash
}

check_visibility() {
    echo "⚙️ Checking visibility of Quilibrium Node..."
    wget -O - "$CHECK_VISIBILITY_URL" | bash
}

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return
    fi
    echo "⚙️ Displaying information about Quilibrium Node..."
    cd "$NODE_PATH" && "$EXEC_START" -node-info
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return
    fi
    echo "⚙️ Displaying logs of Quilibrium Node..."
    sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
}

restart_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return
    fi
    echo "⚙️ Restarting Quilibrium Node service..."
    service ceremonyclient restart
}

stop_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return
    fi
    echo "⚙️ Stopping Quilibrium Node service..."
    service ceremonyclient stop
}

peer_manifest() {
    echo "⚙️ Checking peer manifest (Difficulty metric)..."
    wget --no-cache -O - "$PEER_MANIFEST_URL" | bash
}

node_version() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return
    fi
    echo "⚙️ Displaying Quilibrium Node version..."
    journalctl -u ceremonyclient -r --no-hostname  -n 1 -g "Quilibrium Node" -o cat
}

# Main menu
while true; do
    clear
    
display_menu() {
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
    echo "If you want install a new node choose option 1, and then 2"
    echo ""
    echo "1) Prepare your server"
    echo "2) Install Node"
    echo "------------------------"
    echo "3) Update Node"
    echo "4) Set up gRPCurl"
    echo "5) Check Visibility"
    echo "6) Node Info"
    echo "7) Node Logs (CTRL+C to detatch)"
    echo "8) Restart Node"
    echo "9) Stop Node"
    echo "10) Peer manifest (Difficulty metric)"
    echo "11) Node Version"
    echo "e) Exit"
}

    # Main menu
while true; do
    clear
    display_menu
    
    read -rp "Enter your choice: " choice
    action_performed=0

    case $choice in
        1) confirm_action "This action will install the necessary prerequisites for your server.
            If this is the first time you install a Quilibrium node I suggest you 
            to follow the online guide instead at: https://docs.quilibrium.one/" "Prepare your server" install_prerequisites ;;
        2) confirm_action "This action will install the node on your server.
            If this is the first time you install a Quilibrium node I suggest you 
            to follow the online guide instead at: https://docs.quilibrium.one/
            Ensure that your server meets all the requirements and that you have already prepared you server via Step 1." "Install node" install_node ;;
        3) confirm_action "This action will update your node.
            Only use this if you have installed the node via the guide at https://docs.quilibrium.one/" "Update node" update_node ;;
        4) confirm_action "This action will make some edit to your config.yml to enable communication with the newtwork.
            If this a fresh node installation, let the node run for 30 minutes before doing this." "Set up gRPCurl" configure_grpcurl ;;
        5) check_visibility
            action_performed=1 ;;
        6) node_info
            action_performed=1 ;;
        7) node_logs
            action_performed=1 ;;
        8) restart_node
            action_performed=1 ;;
        9) stop_node
            action_performed=1 ;;
        10) confirm_action "This action will check the peer manifest to provide informatio about the difficulty metric score of your node.
            It only works after 15-30 minutes that the node has been running." "Peer manifest" peer_manifest ;;
        11) node_version
            action_performed=1 ;;
        e) exit ;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    if [ $action_performed -eq 1 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
    fi
done

    while true; do
        clear
        display_menu
    
        read -rp "Enter your choice: " choice
        action_performed=0
    
        case $choice in
            e) exit ;;
            *) echo "Invalid option, please try again." ;;
        esac
    
        if [ $action_performed -eq 1 ]; then
            read -n 1 -s -r -p "Press any key to continue..."
        fi
    done
done

# Check for updates before displaying the menu
check_for_updates
