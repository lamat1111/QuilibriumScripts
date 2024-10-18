#!/bin/bash

# Define the version number here
SCRIPT_VERSION="2.5.0"

INSTALLATION_DIR="/root/ceremonyclient"  # Default installation directory
NODE_DIR="${INSTALLATION_DIR}/node"
CLIENT_DIR="${INSTALLATION_DIR}/client"

#Reload menu
REDRAW_MENU=true


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
check_and_install wget
check_and_install curl

echo

upgrade_qone() {
    # Function to check if the qone.sh setup section is present in .bashrc
    if ! grep -Fxq "# === qone.sh setup ===" ~/.bashrc; then
        # Run the setup script
        # echo "⌛️ Upgrading the qone.sh script... just one minute!"
        sleep 3
        # echo "ℹ️ Downloading qone_setup.sh..."
        if ! wget -qO- https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone_setup.sh | bash; then
            echo "❌ Error: Failed to download and execute qone-setup.sh"
            return 1
        else
            echo "qone.sh upgraded!"
            echo
            echo "✅ To launch the Q1 Quickstart Menu."
            echo "You can simply type 'q1','qone' or run './qone.sh'"
            sleep 1
            # echo "The menu will also load automatically every time you log in."
            # echo "You can disable this feature by running:"
            # echo "sed -i 's|^~/qone.sh|#&|' ~/.bashrc && source ~/.bashrc" 
            echo
            sleep 3
        fi
    else
        echo "✅ qone.sh is already upgraded."
    fi
}

# Function to check for newer script version
check_for_updates() {
    local GITHUB_RAW_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone.sh"
    local LATEST_VERSION
    LATEST_VERSION=$(curl -sS "$GITHUB_RAW_URL" | grep 'SCRIPT_VERSION=' | head -1 | cut -d'"' -f2)
    
    if [ $? -ne 0 ] || [ -z "$LATEST_VERSION" ]; then
        echo "Failed to check for updates. Continuing with current version."
        return 1
    fi
    
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        echo "New version available. Attempting update..."
        if curl -sS -o ~/qone_new.sh "$GITHUB_RAW_URL"; then
            chmod +x ~/qone_new.sh
            mv ~/qone_new.sh ~/qone.sh
            echo "✅ New version ($LATEST_VERSION) installed. Restarting script..."
            exec ~/qone.sh
        else
            echo "Error: Failed to download the new version. Update aborted."
            return 1
        fi
    else
        echo "Current version is up to date."
    fi
}

# Upgrade QONE
#upgrade_qone

# Check for updates
#check_for_updates

#=============================
# VARIABLES
#=============================

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

#=============================
# DETERMINE NODE BINARY PATH
#=============================

# Set the node directory
NODE_DIR="$HOME/ceremonyclient/node"

# Function to find the latest node binary
find_node_binary() {
    if [ -d "$NODE_DIR" ]; then
        find "$NODE_DIR" -name "node-*" -type f -executable 2>/dev/null | sort -V | tail -n 1 | xargs -r basename
    else
        echo ""
    fi
}

# Find the latest node binary
NODE_BINARY=$(find_node_binary)

#=====================
# URLs for scripts
#=====================

# URLs for scripts
PREREQUISITES_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/server_setup.sh"
NODE_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_installer.sh"
QCLIENT_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qclient_install.sh"
GRPCURL_CONFIG_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_gRPC_calls_setup.sh"
NODE_UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
#PEER_MANIFEST_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_peermanifest_checker.sh"
#CHECK_VISIBILITY_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/tools/qnode_visibility_check.sh"
SYSTEM_CLEANER_URL="https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/tools/qnode_system_cleanup.sh"
BACKUP_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_storj.sh"
BACKUP_RESTORE_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_restore_storj.sh"
BALANCE_LOG_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker_installer.sh"
TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"
QCLIENT_ACTIONS_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qclient_actions.sh"

#=====================
# Function Definitions
#=====================

# Function definitions
install_prerequisites() {
    echo
    echo "⌛️  Preparing server with necessary apps and settings..."
    mkdir -p ~/scripts
    rm -f ~/scripts/server_setup.sh
    curl -sSL "$PREREQUISITES_URL" -o ~/scripts/server_setup.sh
    chmod +x ~/scripts/server_setup.sh
    ~/scripts/server_setup.sh
    return $?
}

install_node() {
    echo
    echo "⌛️  Installing node..."
    mkdir -p ~/scripts
    rm -f ~/scripts/qnode_service_installer.sh
    curl -sSL "$NODE_INSTALL_URL" -o ~/scripts/qnode_service_installer.sh
    chmod +x ~/scripts/qnode_service_installer.sh
    ~/scripts/qnode_service_installer.sh
    return $?
}

configure_grpcurl() {
    echo
    echo "⌛️  Setting up gRPCurl..."
    curl -sSL "$GRPCURL_CONFIG_URL" | bash
    return $?
}

update_node() {
    echo
    echo "⌛️  Updating node..."
    mkdir -p ~/scripts
    rm -f ~/scripts/qnode_service_update.sh
    curl -sSL "$NODE_UPDATE_URL" -o ~/scripts/qnode_service_update.sh
    chmod +x ~/scripts/qnode_service_update.sh
    ~/scripts/qnode_service_update.sh
    return $?
}

qclient_install() {
    echo
    echo "⌛️  Installing qClient..."
    mkdir -p ~/scripts
    rm -f ~/scripts/qclient_install.sh
    curl -sSL "$QCLIENT_INSTALL_URL" -o ~/scripts/qclient_install.sh
    chmod +x ~/scripts/qclient_install.sh
    ~/scripts/qclient_install.sh
    return $?
}

qclient_actions() {
    if [ ! -f ~/scripts/qclient_actions.sh ]; then
        mkdir -p ~/scripts
        curl -sSL "$QCLIENT_ACTIONS_URL" -o ~/scripts/qclient_actions.sh
        chmod +x ~/scripts/qclient_actions.sh
    fi
    ~/scripts/qclient_actions.sh
    return $?
}

system_cleaner() {
    echo
    echo "⌛️  Cleaning your system..."
    curl -sSL "$SYSTEM_CLEANER_URL" | bash
    return $?
}

balance_log() {
    echo
    echo "⌛️  Installing the balance log script..."
    curl -sSL "$BALANCE_LOG_URL" | bash
    return $?
}

backup_storj() {
    echo
    echo "⌛️  Downloading Storj backup script..."
    mkdir -p ~/scripts
    rm -f ~/scripts/qnode_backup_storj.sh
    if curl -sSL "$BACKUP_STORJ_URL" -o ~/scripts/qnode_backup_storj.sh; then
        chmod +x ~/scripts/qnode_backup_storj.sh
        if ~/scripts/qnode_backup_storj.sh; then
            echo "✅ Storj backup completed successfully."
        else
            echo "❌ Storj backup script encountered an error."
        fi
    else
        echo "❌ Failed to download Storj backup script."
    fi
    return $?
}

backup_restore_storj() {
    echo
    echo "⌛️  Downloading Storj backup restore script..."
    mkdir -p ~/scripts
    rm -f ~/scripts/qnode_backup_restore_storj.sh
    if curl -sSL "$BACKUP_RESTORE_STORJ_URL" -o ~/scripts/qnode_backup_restore_storj.sh; then
        chmod +x ~/scripts/qnode_backup_restore_storj.sh
        if ~/scripts/qnode_backup_restore_storj.sh; then
            echo "✅ Storj backup restore completed successfully."
        else
            echo "❌ Storj backup restore script encountered an error."
        fi
    else
        echo "❌ Failed to download Storj backup restore script."
    fi
    return $?
}

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    elif [ -z "$NODE_BINARY" ]; then
        echo "Error: No node binary found. Is the node installed correctly?"
    else
        echo
        echo "⌛️  Displaying node info..."
        echo "If this doesn't work you can try the direct commands: https://iri.quest/q-node-info"
        echo
        if [ -d "$NODE_DIR" ]; then
            cd "$NODE_DIR" && ./"$NODE_BINARY" -node-info
        else
            echo "Error: Node directory not found. Is the node installed correctly?"
        fi
        echo
    fi
}

quil_balance() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return 1
    elif [ -z "$NODE_BINARY" ]; then
        echo "Error: No node binary found. Is the node installed correctly?"
        return 1
    else
        echo
        echo "⌛️  Displaying your QUIL balance..."
        echo "The node has to be running for at least 10 minutes for this command to work."
        echo "If it still doesn't work you can try the direct commands: https://iri.quest/q-node-info"
        echo
        if [ -d "$NODE_DIR" ]; then
            cd "$NODE_DIR" && ./"$NODE_BINARY" -balance
        else
            echo "Error: Node directory not found. Is the node installed correctly?"
        fi
        echo
        return 0
    fi
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        display_menu "skip_check"
        return 0
    fi

    echo
    echo "⌛️  Displaying your node log...  (Press CTRL+C to return to the main menu)"
    echo

    # Trap CTRL+C to directly call display_menu
    trap 'display_menu "skip_check"' INT

    sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat

    # If the command exited without CTRL+C, call display_menu
    if [ $? -ne 130 ]; then
        display_menu "skip_check"
    fi
}

return_to_menu() {
    clear
    display_menu
}

start_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️   Starting node service..."
        echo
        service ceremonyclient start
        echo "✅   Node started"
        echo
    fi
}

stop_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️  Stopping node service..."
        echo
        service ceremonyclient stop
        echo "✅   Node stopped"
        echo
    fi
}

node_status() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        press_any_key
    else
        echo
        echo "Quilibrium Node Service Status:"
        systemctl status ceremonyclient.service | grep -E "Active|Main PID|Tasks|Memory|CPU"
        echo
    fi
}

# peer_manifest() {
#     echo "⌛️  Checking peer manifest (Difficulty metric)..."
#     curl -sSL "$PEER_MANIFEST_URL" | bash
#     return $? # This ensures we go back to the main loop
# }

# node_version() {
#     if [ ! -f "$SERVICE_FILE" ]; then
#         echo "$MISSING_SERVICE_MSG"
#         press_any_key
#     else
#         echo
#         echo "⌛️   Displaying node version..."
#         echo
#         journalctl -u ceremonyclient -r --no-hostname  -n 1 -g "Quilibrium Node" -o cat
#         echo
#     fi
# }

best_providers() {
    wrap_text "$best_providers_message"
    echo
    echo "-------------------------------"
}

donations() {
    wrap_text "$donations_message"
    echo
    echo "-------------------------------"
}

disclaimer() {
    wrap_text "$disclaimer_message"
    echo
    echo "-------------------------------"
}


help_message() {
    echo "$help_message"
    echo
    return $?
}


test_script() {
echo "⌛️   Running test script..."
    wget --no-cache -O - "$TEST_URL" | bash
}

# Modify this function to handle "press any key" prompts
press_any_key() {
    echo
    read -n 1 -s -r -p "Press any key to continue..."
    echo
    # Instead of setting REDRAW_MENU, we'll call display_menu directly
    display_menu "skip_check"
}

prompt_return_to_menu() {
    echo -e "\n\n"  # Add two empty lines for readability
    echo "-------------------------------------"
    read -rp "Go back to the main menu? (y/n): " return_to_menu
    case $return_to_menu in
        [Yy]) 
            if [ "$1" != "skip_check" ]; then
                REDRAW_MENU=true
            fi
            display_menu "$1"
            ;;
        *) 
            echo "Exiting the script..."
            exit 0
            ;;
    esac
}


confirm_action() {
    cat << EOF

$1

✅ Do you want to proceed? (y/n):
EOF
    read -p "> " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        $3
        return 0
    else
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

prepare_server_message='
This action will install the necessary prerequisites for your server. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/
'

install_node_message='
This action will install the Qnode & Qclient. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/

Ensure that your server meets all the requirements and that you have 
already prepared you server via Step 1.
'

update_node_message='
This action will update your Qnode & Qclient.
Only use this if you have installed the node via the guide at 
https://docs.quilibrium.one/
'

qclient_install_message='
This action will install or update the Qclient.
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

For more info on how to see/download your balance CSV log, please visit:
https://docs.quilibrium.one/start/tutorials/log-your-node-balance-every-1-hour
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
---------------------
BEST SERVER PROVIDERS
---------------------
Check out the best server providers for your node
at ★ https://iri.quest/q-best-providers ★

Avoid using providers that specifically ban crypto and mining.
'

donations_message='
----------
DONATIONS
----------
Quilbrium.one is a one-man volunteer effort.
If you would like to chip in some financial help, thank you!

You can send ERC-20 tokens at this address:
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013

Or visit this page: https://iri.quest/q-donations
'

disclaimer_message='
------------
DISCLAIMER:
------------
This tool and all related scripts are unofficial and are being shared as-is.
I take no responsibility for potential bugs or any misuse of the available options. 
All scripts are open source; feel free to inspect them before use.

Repo: https://github.com/lamat1111/QuilibriumScripts
'

test_script_message='
This will run the test script.
'

help_message='
=================================
            Q1 HELP
=================================

If something does not work in Q1 please try to update to the
latest version manually by running the code that you find here:
https://docs.quilibrium.one/quilibrium-node-setup-guide/node-quickstart


>> STOP Q1 FROM LOADING ON LOGIN
Please find here: https://docs.quilibrium.one/start/node-quickstart
the command to do this

>> UNINSTALL Q1
To remove the script fomr your system, run: rm ~/qone.sh


>> Q:ONE MENU OPTIONS DETAILS
------------------------------------------------------

 B) Best server providers:
    Check out the best server providers for your node
    at ⭐️ https://iri.quest/q-best-providers ⭐️
    Avoid using providers that specifically ban crypto and mining.

 1) Prepare your server:
    Installs the necessary prerequisites for your server. 
    If this is the first time you install a Quilibrium node, it is recommended
    to follow the online guide at: https://docs.quilibrium.one/

 2) Install node:
    Installs the Qnode & Qclient on your server. 
    If this is the first time you install a Quilibrium node, it is recommended
    to follow the online guide at: https://docs.quilibrium.one/ 
    Ensure that your server meets all the requirements and that you have 
    already prepared your server via Step 1.

 3) Set up gRPCurl:
    Edits your config.yml to enable communication with the network. 
    If this is a fresh node installation, let the node run for 30 minutes before doing this.
    You can run the action multiple times and it wiill not cause issues.

 4) Node Log:
    Displays the log of the node.

 5) Update node:
    Updates your Qnode & Qclient, if necessary.
    Only use this if you have installed the Q1 menu node or the guide at 
    https://docs.quilibrium.one/

 6) Stop node:
    Stops the node.

 7) Start node:
    Starts the node.

 8) Restart node:
    Stop and then starts the node again.

 9) Node info (peerID & balance):
    Displays information about your node peerID and balance.

10) Node status:
    Shows the status of your node service.

11) Balance log:
    Logs your balance every 1 hour on a CSV file.
    For more info on how to see/download your balance CSV log, please visit:
    https://docs.quilibrium.one/start/tutorials/log-your-node-balance-every-1-hour

12) Backup your node:
    Backups your node .config folder and other data on StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

13) Restore backup:
    Restores your node backup from StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

14) System cleaner:
    Performs system cleanup tasks. It will not affect your node.

15) Qclient install:
    Installs or update the Qclient, to manage your QUIL tokens via CLI.

16) Qclient actions:
    Opens a submenu with serveral actions for the Qclient, like: check balance,
    create transaction, accept transaction etc.  

'

#=====================
# Check node and qclient installations
#=====================

# Define color codes
RED='\033[0;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to display version status with color
display_version_status() {
    local current_version=$1
    local latest_version=$2
    local component=$3

    if [ -z "$current_version" ]; then
        echo -e "🔴 ${RED}$component version: Not installed${NC}"
    elif version_gt "$latest_version" "$current_version"; then
        echo -e "🟠 ${RED}$component version: $current_version - update needed${NC}"
    else
        echo -e "🟢 $component version: $current_version - up to date"
    fi
}

# Function to perform a fresh check of installations and versions
fresh_check() {
    # Check node installation and version
    if [ -d "${NODE_DIR}" ]; then
        NODE_BINARY=$(find "${NODE_DIR}" -name "node-*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
        if [ -n "$NODE_BINARY" ]; then
            CURRENT_NODE_VERSION=$(basename "$NODE_BINARY" | grep -oP 'node-\K[0-9]+(\.[0-9]+){2,3}')
            LATEST_NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -oP 'node-\K[0-9]+(\.[0-9]+){2,3}' | sort -V | tail -n 1)
            echo "Node installed: Yes"
            echo "Current Node version: $CURRENT_NODE_VERSION"
            echo "Latest Node version: $LATEST_NODE_VERSION"
        else
            echo "Node installed: Yes, but no executable found"
        fi
    else
        echo "Node installed: No"
    fi

    # Check qclient installation and version
    if [ -d "${CLIENT_DIR}" ]; then
        QCLIENT_BINARY=$(find "${CLIENT_DIR}" -name "qclient-*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
        if [ -n "$QCLIENT_BINARY" ]; then
            CURRENT_QCLIENT_VERSION=$(basename "$QCLIENT_BINARY" | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){2,3}')
            LATEST_QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){2,3}' | sort -V | tail -n 1)
            echo "Qclient installed: Yes"
            echo "Current Qclient version: $CURRENT_QCLIENT_VERSION"
            echo "Latest Qclient version: $LATEST_QCLIENT_VERSION"
        else
            echo "Qclient installed: Yes, but no executable found"
        fi
    else
        echo "Qclient installed: No"
    fi
}

#=====================
# Main Menu Function
#=====================

display_menu() {
    clear
    source ~/.bashrc
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
                              
==================================================================
////////////////// Q1 QUICKSTART MENU - $SCRIPT_VERSION ////////////////////
==================================================================
        Follow the guide at https://docs.quilibrium.one
                    Made with 🔥 by LaMat
------------------------------------------------------------------

EOF

    # Perform a fresh check only if the parameter is not "skip_check"
    if [ "$1" != "skip_check" ]; then
        while IFS= read -r line; do
            if [[ $line == *"Node installed:"* ]]; then
                NODE_INSTALLED=${line#*: }
            elif [[ $line == *"Current Node version:"* ]]; then
                CURRENT_NODE_VERSION=${line#*: }
            elif [[ $line == *"Latest Node version:"* ]]; then
                LATEST_NODE_VERSION=${line#*: }
            elif [[ $line == *"Qclient installed:"* ]]; then
                QCLIENT_INSTALLED=${line#*: }
            elif [[ $line == *"Current Qclient version:"* ]]; then
                CURRENT_QCLIENT_VERSION=${line#*: }
            elif [[ $line == *"Latest Qclient version:"* ]]; then
                LATEST_QCLIENT_VERSION=${line#*: }
            fi
        done < <(fresh_check)
    fi

    if [ "$NODE_INSTALLED" = "Yes" ]; then
        display_version_status "$CURRENT_NODE_VERSION" "$LATEST_NODE_VERSION" "Node"
    else
        echo -e "🔴 ${RED}Node not installed${NC}"
    fi

    if [ "$QCLIENT_INSTALLED" = "Yes" ]; then
        display_version_status "$CURRENT_QCLIENT_VERSION" "$LATEST_QCLIENT_VERSION" "Qclient"
    else
        echo -e "🔴 ${RED}Qclient not installed${NC}"
    fi

    # Display installation instructions only if node is not installed
    if [ "$NODE_INSTALLED" != "Yes" ]; then
        cat << EOF

HOW TO INSTALL A NEW NODE?
Choose option 1, reboot and then choose 2.
Let your node run for 30 minutes, then choose option 3. Done!

1) Prepare your server  
2) Install node
3) Set up gRPCurl   

EOF
    fi

    cat << EOF
-----------------------------------------------------------------
3)  Set up gRPCurl              11) Balance log
4)  Node Log                    12) Backup your node
5)  Update node                 13) Restore backup
6)  Stop node                   14) System cleaner              
7)  Start node                  
8)  Restart node                15) Qclient install/update         
9)  Node info & balance
10) Node status                                                         
-----------------------------------------------------------------
B) ⭐ Best server providers    X) Disclaimer   
D) 💜 Donations                H) Help 
-----------------------------------------------------------------    
E) Exit   
 
                        
EOF
}

# main menu loop
while true; do
    if $REDRAW_MENU; then
        display_menu
        REDRAW_MENU=false
    fi

    read -rp "Enter your choice: " choice
    
    case $choice in
        1) confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites && prompt_return_to_menu "skip_check" ;;
        2) 
            if confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node; then
                prompt_return_to_menu
            fi
            ;;
        3) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPCurl" configure_grpcurl && prompt_return_to_menu "skip_check" ;;
        4) node_logs; press_any_key ;;
        5) 
            if confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node; then
                prompt_return_to_menu
            fi
            ;;
        6) stop_node; press_any_key ;;  
        7) start_node; press_any_key ;;
        8) node_version; press_any_key ;;
        9) node_info; press_any_key ;;
        10) node_status; press_any_key ;;
        11) confirm_action "$(wrap_text "$balance_log_message" "")" "alance log" balance_log && prompt_return_to_menu "skip_check" ;;
        12) confirm_action "$(wrap_text "$backup_storj_message" "")" "Backup your node on StorJ" backup_storj && prompt_return_to_menu "skip_check" ;;
        13) confirm_action "$(wrap_text "$backup_restore_storj_message" "")" "Restore a node backup from StorJ" backup_restore_storj && prompt_return_to_menu "skip_check" ;;
        14) system_cleaner && prompt_return_to_menu "skip_check" ;;
        15) 
            if confirm_action "$(wrap_text "$qclient_install_message" "")" "qClient install" qclient_install; then
                prompt_return_to_menu
            fi
            ;;
        16) qclient_actions;;
        [bB]) best_providers; press_any_key ;;
        [dD]) donations; press_any_key ;;
        [eE]) exit ;;
        [xX]) disclaimer; press_any_key ;;
        [hH]) help_message; press_any_key ;;
        *) echo "Invalid option, please try again."; press_any_key ;;
    esac
done