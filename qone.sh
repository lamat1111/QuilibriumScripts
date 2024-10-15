#!/bin/bash

# Define the version number here
SCRIPT_VERSION="2.0.2"

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
        echo "⌛️ Upgrading the qone.sh script... just one minute!"
        sleep 3
        echo "ℹ️ Downloading qone_setup.sh..."
        if ! wget -qO- https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone_setup.sh | bash; then
            echo "❌ Error: Failed to download and execute qone-setup.sh"
            return 1
        else
            echo "✅ qone.sh upgraded!"
            echo
            echo "🟢 To launch the QONE Quickstart Menu."
            echo "You can simply type 'q1', or run './qone.sh'"
            sleep 1
            echo "The menu will also load automatically every time you log in."
            echo "You can disable this feature by running:"
            echo "sed -i 's|^~/qone.sh|#&|' ~/.bashrc && source ~/.bashrc" 
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
upgrade_qone

# Check for updates
check_for_updates

#=============================
# VARIABLES
#=============================

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

# Node version
#NODE_VERSION="1.4.20.1"

#=============================
# DETERMINE NODE BINARY PATH
#=============================

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine the node version
NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -E "^node-[0-9]+(\.[0-9]+)*" | grep -v "dgst" | sed 's/^node-//' | cut -d '-' -f 1 | head -n 1)

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        NODE_BINARY="node-$NODE_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        NODE_BINARY="node-$NODE_VERSION-darwin-arm64"
    fi
fi

#=====================
# URLs for scripts
#=====================

# URLs for scripts
PREREQUISITES_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/server_setup.sh"
NODE_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_installer.sh"
QCLIENT_INSTALL_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qclient_install.sh"
GRPCURL_CONFIG_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_gRPC_calls_setup.sh"
NODE_UPDATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
PEER_MANIFEST_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qnode_peermanifest_checker.sh"
CHECK_VISIBILITY_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/tools/qnode_visibility_check.sh"
SYSTEM_CLEANER_URL="https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/tools/qnode_system_cleanup.sh"
BACKUP_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_storj.sh"
BACKUP_RESTORE_STORJ_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_restore_storj.sh"
BALANCE_LOG_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker_installer.sh"
TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"

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
    prompt_return_to_menu
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
    prompt_return_to_menu
    return $?
}

configure_grpcurl() {
    echo
    echo "⌛️  Setting up gRPCurl..."
    curl -sSL "$GRPCURL_CONFIG_URL" | bash
    prompt_return_to_menu
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
    
    prompt_return_to_menu
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
    
    prompt_return_to_menu
    return $?
}

check_visibility() {
    echo
    echo "⌛️  Checking node visibility..."
    curl -sSL "$CHECK_VISIBILITY_URL" | bash
    prompt_return_to_menu
    return $?
}

system_cleaner() {
    echo
    echo "⌛️  Cleaning your system..."
    curl -sSL "$SYSTEM_CLEANER_URL" | bash
    prompt_return_to_menu
    return $?
}

balance_log() {
    echo
    echo "⌛️  Installing the balance log script..."
    curl -sSL "$BALANCE_LOG_URL" | bash
    prompt_return_to_menu
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
    prompt_return_to_menu
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
    prompt_return_to_menu
    return $?
}

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️  Displaying node info..."
        echo "If this doesn't work you can try the direct commands: https://iri.quest/q-node-info"
        echo
        cd ~/ceremonyclient/node && ./"$NODE_BINARY" -node-info
        echo
    fi
}


quil_balance() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return 1
    else
        echo
        echo "⌛️  Displaying your QUIL balance..."
        echo "The node has to be running for at least 10 minutes for this command to work."
        echo "If is still doesn't work you can try the direct commands: https://iri.quest/q-node-info"
        echo
        cd ~/ceremonyclient/node && ./"$NODE_BINARY" -balance
        echo
        return 0
    fi
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        read -n 1 -s -r -p "✅  Press any key to continue..."
        echo  # Add an empty line for better readability
        return 0
    fi
    echo
    echo "⌛️  Displaying your node log...  (Press CTRL+C to return to the main menu)"
    echo
    trap 'return' INT  # Trap CTRL+C to just return from the function
    sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
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

peer_manifest() {
    echo "⌛️  Checking peer manifest (Difficulty metric)..."
    curl -sSL "$PEER_MANIFEST_URL" | bash
    prompt_return_to_menu
    return $? # This ensures we go back to the main loop
}

node_version() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️   Displaying node version..."
        echo
        journalctl -u ceremonyclient -r --no-hostname  -n 1 -g "Quilibrium Node" -o cat
        echo
    fi
}

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
    prompt_return_to_menu
    return $?
}


test_script() {
echo "⌛️   Running test script..."
    wget --no-cache -O - "$TEST_URL" | bash
}


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

qclient_install_message='
This action will install or update the qClient.
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

disclaimer_message='
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
    Stops the node.

 7) Start node:
    Starts the node.

 8) Node version:
    Display the version of the node.

 9) Node info (peerID & balance):
    Display information about your node peerID and balance.

10) Check balance:
    Display the balance of QUIL tokens.

11) Balance log:
    Log your balance every 1 hour on a CSV file.
    For more info on how to see/download your balance CSV log, please visit:
    https://docs.quilibrium.one/start/tutorials/log-your-node-balance-every-1-hour

12) Backup your node:
    Backup of your node .config folder and other data on StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

13) Restore backup:
    This script will restore your node backup from StorJ.
    You need a Storj account https://www.storj.io/ and a Public/Secret access key.

14) qClient install:
    Install or update the qClient, to manage your QUIL tokens via CLI.

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
               ✨✨✨ Q1 QUICKSTART MENU ✨✨✨
                           v $SCRIPT_VERSION
==================================================================
        Follow the guide at https://docs.quilibrium.one
                    Made with 🔥 by LaMat
==================================================================
EOF
    cat << "EOF"

HOW TO INSTALL A NEW NODE?
Choose option 1, reboot and then choose 2.
Let your node run for 30 minutes, then choose option 3. Done!

-----------------------------------------------------------------
1) Prepare your server        10) Check balance
2) Install node               11) Balance log
3) Set up gRPCurl             12) Backup your node
                              13) Restore backup                
4) Node Log                                    
5) Update node                14) qClient install      
6) Stop node                                               
7) Start node                 15) Check visibility                 
8) Node version               16) System cleaner               
9) Node info                                      
-----------------------------------------------------------------
B) ⭐️ Best server providers
D) 💜 Donations
-----------------------------------------------------------------    
X) Disclaimer                 E) Exit   
H) Help  
                        

EOF
}

#20) Test Script

#=====================
# Main Menu Loop
#=====================

while true; do
    display_menu
    
    read -rp "Enter your choice: " choice
    
    case $choice in
        1) confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites && continue ;;
        2) confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node && continue ;;
        3) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPCurl" configure_grpcurl && continue ;;
        4) node_logs; continue ;;
        5) confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node && continue ;;
        6) stop_node ;;
        7) start_node ;;
        8) node_version ;;
        9) node_info ;;
        10) quil_balance ;;
        11) confirm_action "$(wrap_text "$balance_log_message" "")" "Balance log" balance_log && continue ;;
        12) confirm_action "$(wrap_text "$backup_storj_message" "")" "Backup your node on StorJ" backup_storj && continue ;;
        13) confirm_action "$(wrap_text "$backup_restore_storj_message" "")" "Restore a node backup from StorJ" backup_restore_storj && continue ;;
        14) confirm_action "$(wrap_text "$qclient_install_message" "")" "qClient install" qclient_install && continue ;;
        #14) confirm_action "$(wrap_text "$peer_manifest_message" "")" "Peer manifest" peer_manifest && continue ;;
        15) check_visibility && continue ;;
        16) system_cleaner && continue ;;
        20) confirm_action "$(wrap_text "$test_script_message" "")" "Test Script" test_script && continue ;;
        [bB]) best_providers ;;
        [dD]) donations ;;
        [eE]) exit ;;
        [xX]) disclaimer ;;
        [hH]) help_message && continue ;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    # Only prompt if the action didn't use continue
    read -n 1 -s -r -p "Press any key to continue..."
done
