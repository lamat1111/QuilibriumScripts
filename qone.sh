#!/bin/bash

# Define the version number here
SCRIPT_VERSION="1.7.1"

# Function to check if wget is installed, and install it if it is not
check_wget() {
    if ! command -v wget &> /dev/null; then
        echo "❌ wget not found. Installing..."
        sudo apt-get update && sudo apt-get install -y wget || { echo "❌ wget installation failed."; exit 1; }
    fi
}

# Check if wget is installed
check_wget

upgrade_qone() {
    # Function to check if the qone.sh setup section is present in .bashrc
    if ! grep -Fxq "# === qone.sh setup ===" ~/.bashrc; then
        # Run the setup script
        echo "⌛️ Upgrading the qone.sh script... just one minute!"
        sleep 3
        echo "ℹ️ Downloading qone_setup.sh..."
        if ! wget -qO- https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone_setup.sh | bash; then
            echo "❌ Error: Failed to download and execute qone-setup.sh"
            return 1
        else
            echo "✅ qone.sh upgraded!"
            echo ""
            echo "🟢 You can now use 'Q1', 'q1', or 'qone' to launch the Node Quickstart Menu."
            sleep 1
            echo "🟢 The menu will also load automatically every time you log in."
            echo ""
            sleep 5
        fi
    else
        echo "ℹ️ qone.sh is already upgraded."
    fi
}

# Function to check for newer script version
check_for_updates() {
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/qone.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/qone.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/qone.sh"
        echo "✅ New version downloaded: V $SCRIPT_VERSION."
	sleep 1
    fi
}

# Upgrade QONE
upgrade_qone

# Check for updates
check_for_updates

#=============================
# VARIABLES
#=============================

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# User working folder
USER_HOME=$(eval echo ~$USER)

#Node path
NODE_PATH="$HOME/ceremonyclient/node"

# Version number
#NODE_VERSION="1.4.19.1"

#=============================
# DETERMINE NODE BINARY PATH
#=============================

# Determine OS and architecture
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    release_os="linux"
    release_arch=$(uname -m)
    if [[ "$release_arch" == "aarch64" ]]; then
        release_arch="arm64"
    else
        release_arch="amd64"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    release_os="darwin"
    release_arch="arm64"
else
    echo "unsupported OS for releases, please build from source"
    exit 1
fi

fetch() {
    # Fetch available files for the determined OS and architecture
    files=$(curl -s https://releases.quilibrium.com/release | grep $release_os-$release_arch)

    # Extract the version from the first matching file
    for file in $files; do
        version=$(echo "$file" | cut -d '-' -f 2)
        break
    done
}

fetch

# Set the node binary name based on the determined OS, architecture, and version
NODE_BINARY=node-$version-$release_os-$release_arch



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
BACKUP_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_storj.sh"
BACKUP_RESTORE_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_restore_storj.sh"
BALANCE_LOG_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker_installer.sh"
TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

# Function definitions
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

balance_log() {
    echo ""
    echo "⌛️  Installing the balance log script..."
    wget -O - "$BALANCE_LOG_URL" | bash
    prompt_return_to_menu
}

backup_storj() {
    echo ""
    echo "⌛️  Downloading Storj backup script..."
    mkdir -p ~/scripts && wget -P ~/scripts -O ~/scripts/qnode_backup_storj.sh "$BACKUP_STORJ_URL"
    if [ -f ~/scripts/qnode_backup_storj.sh ]; then
        chmod +x ~/scripts/qnode_backup_storj.sh
        ~/scripts/qnode_backup_storj.sh
    else
        echo "❌ Failed to download Storj backup script."
    fi
    prompt_return_to_menu
}

backup_restore_storj() {
    echo ""
    echo "⌛️  Downloading Storj backup restore script..."
    mkdir -p ~/scripts && wget -P ~/scripts -O ~/scripts/qnode_backup_restore_storj.sh "$BACKUP_RESTORE_STORJ_URL"
    if [ -f ~/scripts/qnode_backup_restore_storj.sh ]; then
        chmod +x ~/scripts/qnode_backup_restore_storj.sh
        ~/scripts/qnode_backup_restore_storj.sh
    else
        echo "❌ Failed to download Storj backup restore script."
    fi
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
    echo "If this doesn't work you can try the direct commands: https://iri.quest/q-node-info"
	echo ""
    	sleep 1
        cd ~/ceremonyclient/node && ./"$NODE_BINARY" -node-info
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
        echo "If this doesn't work you can try the direct commands: https://iri.quest/q-node-info"
	    echo ""
    	sleep 1
        cd ~/ceremonyclient/node && ./"$NODE_BINARY" -balance
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

best_providers() {
    wrap_text "$best_providers_message"
    echo ""
    echo "-------------------------------"
    read -n 1 -s -r -p "✅  Press any key to continue..."  # Pause and wait for user input
}


donations() {
    wrap_text "$donations_message"
    echo ""
    echo "-------------------------------"
    read -n 1 -s -r -p "✅  Press any key to continue..."  # Pause and wait for user input
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

balance_log_message='
This installer sets up a script to check your node balance
and then sets up a cronjob to log your balance every hour in a CSV file.
'

backup_storj_message='
This action automates the backup of your node data to StorJ.
You need a StorJ account https://www.storj.io/ and a Public/Secret access key.
For security we suggest you to create a bucket specific to Quilibrium, and specific keys for accessing only that bucket.
'

backup_restore_storj_message='
This action restores a backup of the node '.config' folder from StorJ.
It will only work if you performed the .config folder backup via the script
in the Q.One Quickstart menu.
'

best_providers_message='
Check out the best server providers for your node
at ⭐️ https://iri.quest/q-best-providers ⭐️

Avoid using providers that specifically ban crypto and mining.
'

donations_message='
Quilbrium.one is a one-man volunteer effort.
If you would like to chip in some financial help, thank you!

You can send ERC-20 tokens at this address:
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013

Or visit this page: https://iri.quest/q-donations
'

test_script_message='
This will run the test script.
'

help_message='
=================================
            Q.ONE HELP
=================================

If something does not work in Q.ONE please try to update to the
latest version manually by running the code that you find here:
https://docs.quilibrium.one/quilibrium-node-setup-guide/node-quickstart


>> STOP Q.ONE FROM LOADING ON LOGIN
Please find here: https://docs.quilibrium.one/start/node-quickstart
the command to do this

>> UNINSTALL Q.ONE
To remove the script fomr your system, run: rm ~/qone.sh


>> Q:ONE MENU OPTIONS DETAILS
------------------------------------------------------

 B) Best server providers:
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

10) Check balance:
    Display the balance of QUIL tokens.

11) Balance log:
    Log your balance every 1 hour on a CSV file.

12) Backup your node:
    Backup of your node .config folder and other data on StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

13) Restore backup:
    This script will restore your node backup from StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

14) Peer manifest (Difficulty metric):
    Check the peer manifest to provide information about the difficulty metric score of your node. 
    It only works after the node has been running for 15-30 minutes.

15) Check visibility:
    Check the visibility status of the node.

16) System cleaner:
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


=======================================================================
                ✨✨✨ Q.ONE QUICKSTART MENU ✨✨✨
=======================================================================
           Follow the guide at https://docs.quilibrium.one

                       Made with 🔥 by LaMat
=======================================================================

EOF
    cat << "EOF"
HOW TO INSTALL A NEW NODE?
Choose option 1, reboot and and then choose 2.
Let your node run for 30 minutes, then choose option 3. Done!

----------------------------------------------------------------------
1) Prepare your server        10) Check balance
2) Install node               11) Balance log
3) Set up gRPCurl             12) Backup your node
                              13) Restore backup                
4) Node Log                                    
5) Update node                14) Peer manifest         
6) Stop node                  15) Check visibility                              
7) Restart node               16) System cleaner 
8) Node version                 
9) Node info                     
----------------------------------------------------------------------
B) ⭐️ Best server providers
D) 💜 Donations
----------------------------------------------------------------------     
E) Exit                          H) Help
                        

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
        11) confirm_action "$(wrap_text "$balance_log_message" "")" "Balance log" balance_log;;
        12) confirm_action "$(wrap_text "$backup_storj_message" "")" "Backup your node on StorJ" backup_storj;;
        13) confirm_action "$(wrap_text "$backup_restore_storj_message" "")" "Restore a node backup frm STorJ" backup_restore_storj;;
        14) confirm_action "$(wrap_text "$peer_manifest_message" "")" "Peer manifest" peer_manifest;;
        15) check_visibility;;
	    16) system_cleaner;;
	    20) confirm_action "$(wrap_text "$test_script_message" "")" "Test Script" test_script;;
        [bB]) best_providers;;
        [dD]) donations;;
        [eE]) exit ;;
	    [hH]) help_message;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    if [ $action_performed -eq 1 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
    fi
done
