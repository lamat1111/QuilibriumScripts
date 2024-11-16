#!/bin/bash

# Define the version number here
SCRIPT_VERSION="2.7.0"

# ------------------------------------------------------------------
SHOW_TEMP_MESSAGE=true  # Toggle to control message visibility
TEMP_MESSAGE=$(cat << 'EOF'
➤ Join the Q1 Telegram channel >> https://t.me/quilibriumone
➤ for important updates on all Q1 scripts.
EOF
)

#=====================
# Menu interface
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
             Node guide: https://docs.quilibrium.one
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
    # Autoudpate Toggle
    echo
    echo -e "Auto-update: $([ "$(check_autoupdate_status)" = "ON" ] && echo "🟢" || echo "🔴") $(check_autoupdate_status)"

    # Display installation instructions only if node is not installed
    if [ "$NODE_INSTALLED" != "Yes" ]; then
        cat << EOF

HOW TO INSTALL A NEW NODE?
Choose option 1, reboot and then choose 2.
Let your node run for 30 minutes, then choose option 3. Done!

1) Prepare your server  
2) Install node
3) Set up gRPC   

EOF
    fi

    cat << EOF
-----------------------------------------------------------------
3)  Set up gRPC                 11) Balance log
4)  Node Log                    12) Backup your node
5)  Update node                 13) Restore backup
6)  Stop node                              
7)  Start node                  14) Qclient install/update
8)  Restart node                15) Qclient actions
9)  Node info & balance          
10) Node status                 16) Proof rate check (BETA)
-----------------------------------------------------------------
P) Prover Pause                  H) Help 
A) Auto-update ON/OFF            X) Disclaimer                                             
M) Menu autoload on login       
----------------------------------------------------------------- 
B) ⭐ Best server providers     D) 💜 Donations 
-----------------------------------------------------------------   
E) Exit                         
 
                        
EOF
}

#=====================
# Main Menu loop
#=====================


main() {
    while true; do
        if $REDRAW_MENU; then
            display_menu
            REDRAW_MENU=false
        fi

        display_temp_message

        read -rp "Enter your choice: " choice
        
        
        case $choice in
            1) 
                if confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites; then
                    prompt_return_to_menu "skip_check"
                fi
                ;;
            2) 
                if confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node; then
                    prompt_return_to_menu
                fi
                ;;
            3) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPC" configure_grpcurl && prompt_return_to_menu "skip_check" ;;
            4) node_logs; display_menu "skip_check" ;;
            5) 
                if confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node; then
                    prompt_return_to_menu
                fi
                ;;
            6) stop_node; press_any_key ;;  
            7) start_node; press_any_key ;;
            8) restart_node; press_any_key ;;
            9) node_info; press_any_key ;;
            10) node_status; press_any_key ;;
            11) balance_log && prompt_return_to_menu "skip_check" ;;
            12) confirm_action "$(wrap_text "$backup_storj_message" "")" "Backup your node on StorJ" backup_storj && prompt_return_to_menu "skip_check" ;;
            13) confirm_action "$(wrap_text "$backup_restore_storj_message" "")" "Restore a node backup from StorJ" backup_restore_storj && prompt_return_to_menu "skip_check" ;;
            #14) system_cleaner && prompt_return_to_menu "skip_check" ;;
            14) 
                if confirm_action "$(wrap_text "$qclient_install_message" "")" "qClient install" qclient_install; then
                    prompt_return_to_menu
                fi
                ;;
            15) qclient_actions; clear; display_menu "skip_check" ;;
            16) proof_rate; press_any_key ;;
            [aA]) toggle_autoupdate; press_any_key ;;
            [bB]) best_providers; press_any_key ;;
            [dD]) donations; press_any_key ;;
            [eE]) exit ;;
            [mM]) handle_menu_autoload; press_any_key ;;
            [pP]) confirm_action "$(wrap_text "$prover_pause_message" "")" "Send a 'Prover Pause' message" prover_pause && prompt_return_to_menu "skip_check" ;;
            [xX]) disclaimer; press_any_key ;;
            [hH]) help_message; press_any_key ;;
            *) echo "Invalid option, please try again."; press_any_key ;;
        esac
    done
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
⚠️ It is strongly advised to backup your "node/.config" folder before updating the node

This action will update your Node & Qclient.
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

prover_pause_message='
This action will send a pause message to the network.
Only use this to avoid penalties if your machine has crashed for hardware failure and cannot recover.
'

balance_log_message='
This installer sets up a script to check your node balance
and then sets up a cronjob to log your balance every hour in a CSV file.

To see your existing balance log run "cat ~/scripts/balance_log.csv"

To download the balance log directly run visit:
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

You can send native QUIL at this address:
0x0e15a09539c95784c8d7e1b80beb175f12967764daa7d19626cc526575483180

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

>> FOLDERS!
The menu will work correctly only if your node istallation follows the default folder structure.
> Node: "$HOME/ceremonyclient/node"
> Qclient: "$HOME/ceremonyclient/client"
> .config folder: "$HOME/ceremonyclient/node/"
> Service name: "ceremonyclient"

>> NODE/QCLIENT is installed, but menu says not installed
In some rare cases the menu may not telling the truth...
But you can always check by looking at your Node log or by trying to use the Qclient

>> UNINSTALL Q1 MENU
To remove the script completely, run: rm ~/qone.sh

------------------------------------------------------
>> Q1 MENU OPTIONS DETAILS
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

 3) Set up gRPC:
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

14) Qclient install:
    Installs or update the Qclient, to manage your QUIL tokens via CLI.

15) Qclient actions:
    Opens a submenu with serveral actions for the Qclient, like: check balance,
    create transaction, accept transaction etc.  

16) Auto-update ON/OFF:
    Sets up auto-updates for Node and Qclient via service file and timer.
    If they are already set up, it will activate or deactivate them on user choice.
    The timer checks for updates every 1 hour at a random minute.
    Only use if you run with sudo privileges.
    In general, not recommended as autoupdating can lead to issues and penalties,
    if something goes wrong and you are not there to fix the issue.

17) Proof rate monitor:
    Calculates the rate at which your node is submitting proofs in the last 3 hours.
    To run for a different time window you can run:
    '\$HOME/scripts/qnode_proof_rate.sh \x', where x is a number of minutes,
    e.g. \$HOME/scripts/qnode_proof_rate.sh 600

 P) Prover Pause:
    Sends a pause message to the network. Only use this to avoid
    penalties if your machine has crashed due to hardware failure
    and cannot recover.

 A) Menu autoload on login:
    Toggles whether the Q1 menu automatically loads when you
    log in via SSH. When enabled, provides quick access to
    node management tools.

'

#=====================
# MENU options functions
#=====================

# Function definitions
install_prerequisites() {
    echo
    echo "⌛️ Preparing server with necessary apps and settings..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/server_setup.sh "$PREREQUISITES_URL"
    chmod +x ~/scripts/server_setup.sh
    ~/scripts/server_setup.sh
    return $?
}

install_node() {
    echo
    echo "⌛️ Installing node..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/qnode_service_installer.sh "$NODE_INSTALL_URL"
    chmod +x ~/scripts/qnode_service_installer.sh
    ~/scripts/qnode_service_installer.sh
    return $?
}

configure_grpcurl() {
    echo
    echo "⌛️  Setting up gRPCurl..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/qnode_gRPC_calls_setup.sh "$GRPCURL_CONFIG_URL"
    chmod +x ~/scripts/qnode_gRPC_calls_setup.sh
    ~/scripts/qnode_gRPC_calls_setup.sh
    return $?
}

update_node() {
    echo
    echo "⌛️ Updating node..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/qnode_service_update.sh "$NODE_UPDATE_URL"
    chmod +x ~/scripts/qnode_service_update.sh
    ~/scripts/qnode_service_update.sh
    return $?
}

autoupdate_setup() {
    echo
    echo "Only use this option if you run your machine with sudo privileges"
    echo
    echo "⌛️ Setting up auto-update..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/qnode_autoupdate_setup.sh "$AUTOUPDATE_SETUP_URL"
    chmod +x ~/scripts/qnode_autoupdate_setup.sh
    ~/scripts/qnode_autoupdate_setup.sh
    return $?
}

qclient_install() {
    echo
    echo "⌛️ Installing qClient..."
    mkdir -p ~/scripts
    curl -sSL -o ~/scripts/qclient_install.sh "$QCLIENT_INSTALL_URL"
    chmod +x ~/scripts/qclient_install.sh
    ~/scripts/qclient_install.sh
    return $?
}

qclient_actions() {
    clear  # This clears everything, including the main menu
    
    if [ ! -f ~/scripts/qclient_actions.sh ]; then
        mkdir -p ~/scripts
        curl -sSL -o ~/scripts/qclient_actions.sh "$QCLIENT_ACTIONS_URL"
        chmod +x ~/scripts/qclient_actions.sh
    fi
    
    ~/scripts/qclient_actions.sh # This runs in the cleared screen
    local exit_status=$?

    # Only redraw menu if we didn't exit the qclient actions menu
    if [ $exit_status -eq 0 ]; then
        clear
        display_menu "skip_check"
    fi
    return $exit_status
}

system_cleaner() {
    echo
    echo "⌛️  Cleaning your system..."
    curl -sSL "$SYSTEM_CLEANER_URL" | bash
    return $?
}

balance_log() {
    echo
    if [ -f "$HOME/scripts/qnode_balance_checker.sh" ] && crontab -l | grep -q "qnode_balance_checker.sh"; then
        echo "Balance log is already set up. What would you like to do?"
        echo
        echo "1 - Download balance log"
        echo "2 - See balance log"
        echo "3 - Clean balance log"
        echo
        read -p "Enter your choice (1, 2 or 3): " choice

        case $choice in
            1)
                echo
                mkdir -p ~/scripts && \
                curl -sSL -o ~/scripts/qnode_balance_log_download.sh "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_log_download.sh" && \
                chmod +x ~/scripts/qnode_balance_log_download.sh && \
                ~/scripts/qnode_balance_log_download.sh
                ;;
            2)
                if [ -f "$HOME/scripts/balance_log.csv" ]; then
                    echo
                    echo "Balance Log"
                    echo "================="
                    echo
                    cat "$HOME/scripts/balance_log.csv"
                else
                    echo "Balance log file not found."
                fi
                ;;
            3)
                echo "This option will completely delete your balance log. Proceed? (y/n)"
                read -p "> " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if rm "$HOME/scripts/balance_log.csv"; then
                        echo "Balance log has been deleted."
                    else
                        echo "Error: Failed to delete balance log or file doesn't exist."
                    fi
                else
                    echo "Operation cancelled."
                fi
                ;;
            *)
                echo "Invalid choice. Please run the balance log option again."
                ;;
        esac
    else
        echo "⌛️  Installing the balance log script..."
        curl -sSL "$BALANCE_LOG_URL" | bash
    fi
    return $?
}

backup_storj() {
    echo
    echo "⌛️  Downloading Storj backup script..."
    mkdir -p ~/scripts
    if curl -sSL -o ~/scripts/qnode_backup_storj.sh "$BACKUP_STORJ_URL"; then
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
    if curl -sSL -o ~/scripts/qnode_backup_restore_storj.sh "$BACKUP_RESTORE_STORJ_URL"; then
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

quil_balance() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return 1
    elif [ -z "$NODE_EXEC" ]; then
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

node_info() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    elif [ -z "$NODE_EXEC" ]; then
        echo "Error: No node binary found. Is the node installed correctly?"
    else
        echo
        echo "⌛️  Displaying node info..."
        echo
        if [ -d "$NODE_DIR" ]; then
            cd "$NODE_DIR" && ./"$NODE_BINARY" -node-info
        else
            echo "Error: Node directory not found. Is the node installed correctly?"
        fi
        echo
        echo "------------------------------------"
        echo "If this doesn't work you can try the direct commands: https://iri.quest/q-node-info"
        echo "If you where on public RPC previously, and receive errors when querying your -node-info,"
        echo "you may want to restart your node and let it run until it begins to sync."
    fi
}

node_logs() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        return 1
    fi

    echo
    echo "⌛️  Displaying your node log...  (Press CTRL+C to return to the main menu)"
    echo

    # Create a subshell for the log monitoring
    (
        # Trap CTRL+C within the subshell
        trap 'exit 0' INT

        sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat | while read -r line; do
            timestamp=$(date "+%b %d %H:%M:%S")
            echo "$timestamp $(echo "$line" | sed -E 's/"level":"info","ts":[0-9.]+,//')"
        done
    )
}

start_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️ Starting node service..."
        echo
        service ceremonyclient start
        echo "✅ Node started"
        echo
    fi
}

stop_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️ Stopping node service..."
        echo
        service ceremonyclient stop
        echo "🔴 Node stopped"
        echo
    fi
}

restart_node() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
    else
        echo
        echo "⌛️ Restarting node service..."
        echo
        service ceremonyclient restart
        echo "✅ Node restarted"
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
        echo

        # Get the status output, excluding log entries
        systemctl status ceremonyclient.service --no-pager | 
        awk '
        /^[●○]/ { print; in_cgroup = 0; next }
        /^ *(Loaded|Active|Process|Main PID|Tasks|Memory|CPU):/ { print; in_cgroup = 0; next }
        /^     CGroup:/ { print; in_cgroup = 1; next }
        in_cgroup == 1 && /^[[:space:]]/ { print; next }
        in_cgroup == 1 && $0 == "" { exit }
        '

        echo
    fi
}

proof_rate() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "$MISSING_SERVICE_MSG"
        press_any_key
    else
        echo
        mkdir -p ~/scripts
        curl -sSL -o ~/scripts/qnode_proof_rate.sh "$PROOF_RATE_URL"
        chmod +x ~/scripts/qnode_proof_rate.sh
        ~/scripts/qnode_proof_rate.sh
        return $?
    fi
}

prover_pause() {
    # First check if the node binary exists
    if [ -z "$QCLIENT_EXEC" ]; then
        echo "Error: Qclient not found. Is it installed correctly?"
        return 1
    fi

    # Check if the service is running
    if systemctl is-active --quiet ceremonyclient.service; then
        echo
        echo "⚠️ It seems your node is running correctly, are you sure you want to send the \"Prover Pause\" message?"
        read -p "Proceed? (y/n): " second_confirm
        if [[ ! "$second_confirm" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    echo
    echo "⌛️ Sending Prover Pause message..."
    # Execute the prover pause command
    if "$QCLIENT_EXEC" config prover pause --config "$HOME/ceremonyclient/node/.config"; then
        echo "✅ Prover Pause message sent successfully."
        return 0
    else
        echo "❌ Failed to send Prover Pause message."
        return 1
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


#==========================
# CHECK UPDATES
#==========================

# Function to check for newer script version
check_for_updates() {
    local SCRIPT_NAME="qone"
    local SCRIPT_VERSION="${SCRIPT_VERSION:-0.0.0}"  # Fallback if not defined
    local GITHUB_RAW_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/qone.sh"
    local LATEST_VERSION
    
    LATEST_VERSION=$(curl -sS "$GITHUB_RAW_URL" | grep 'SCRIPT_VERSION=' | head -1 | cut -d'"' -f2)
    
    if [ $? -ne 0 ] || [ -z "$LATEST_VERSION" ]; then
        echo "Failed to check for updates. Continuing with current version."
        return 1
    fi
    
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        echo "New version available. Attempting update..."
        if curl -sS -o "${HOME}/${SCRIPT_NAME}_new.sh" "$GITHUB_RAW_URL"; then
            chmod +x "${HOME}/${SCRIPT_NAME}_new.sh"
            mv "${HOME}/${SCRIPT_NAME}_new.sh" "${HOME}/${SCRIPT_NAME}.sh"
            echo "✅ New version ($LATEST_VERSION) installed. Restarting script..."
            exec "${HOME}/${SCRIPT_NAME}.sh"
        else
            echo "Error: Failed to download the new version. Update aborted."
            return 1
        fi
    else
        echo "Current version is up to date."
    fi
}

#==========================
# ADD ALIASES
#==========================

setup_aliases() {
    SCRIPTS_DIR="$HOME/scripts"
    ALIAS_MARKER_FILE="$SCRIPTS_DIR/.q1_alias_added"

    # Ensure the scripts directory exists
    mkdir -p "$SCRIPTS_DIR"

    if [ ! -f "$ALIAS_MARKER_FILE" ]; then
        echo "⌛️ Setting up aliases..."

        # Remove old alias block (from old script versions)
        sed -i '/=== qone.sh setup ===/,/=== end qone.sh setup ===/d' "$HOME/.bashrc"

        # Remove new alias block (from newer script versions)
        sed -i '/=== qone.sh aliases ===/,/=== end qone.sh aliases ===/d' "$HOME/.bashrc"

        # Add the new alias setup
        cat << 'EOF' >> "$HOME/.bashrc"

# === qone.sh aliases ===
# The following lines are added to create aliases for qone.sh
alias qone='~/qone.sh'
alias q1='~/qone.sh'
# === end qone.sh aliases ===
EOF

        # Create marker file to prevent redundant setup
        touch "$ALIAS_MARKER_FILE"
        
        # Source .bashrc to make sure aliases are available immediately
        if [ -n "$BASH_VERSION" ]; then
            source "$HOME/.bashrc"
            echo "Aliases 'q1' and 'qone' are now active."
        else
            echo "Please run 'source ~/.bashrc' or restart your terminal to use the 'q1' and 'qone' commands."
        fi
    else
        : #echo "Aliases are already set up."
    fi
}


#=============================
# VARIABLES
#=============================

#Reload menu
REDRAW_MENU=true

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Common message for missing service file
MISSING_SERVICE_MSG="⚠️ Your service file does not exist. Looks like you do not have a node running as a service yet!"

INSTALLATION_DIR="$HOME/ceremonyclient"  # Default installation directory
NODE_DIR="${INSTALLATION_DIR}/node"
CLIENT_DIR="${INSTALLATION_DIR}/client"

# Find the latest executables
NODE_EXEC=$(find "${NODE_DIR}" -name "node-[0-9]*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
QCLIENT_EXEC=$(find "${CLIENT_DIR}" -name "qclient-[0-9]*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
NODE_BINARY=$(basename "$NODE_EXEC")

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
QCLIENT_ACTIONS_URL="https://raw.githubusercontent.com/lamat1111/quilibriumscripts/master/tools/qclient_actions.sh"
AUTOUPDATE_SETUP_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_autoupdate_setup.sh"
PROOF_RATE_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_proof_rate.sh"

TEST_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/test_script.sh"

#=====================
# Autoupdate Toggle 
#=====================

# Function to check if auto-update service files exist
check_autoupdate_files() {
    if [ -f "/etc/systemd/system/qnode-autoupdate.service" ] && [ -f "/etc/systemd/system/qnode-autoupdate.timer" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check the status of the auto-update service
check_autoupdate_status() {
    if check_autoupdate_files; then
        if systemctl is-active --quiet qnode-autoupdate.timer; then
            echo "ON"
        else
            echo "OFF"
        fi
    else
        echo "OFF"
    fi
}

# Function to set up auto-update
setup_autoupdate() {
    echo "⌛️ Setting up auto-update..."
    mkdir -p ~/scripts && \
    curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_autoupdate_setup.sh" -o ~/scripts/qnode_autoupdate_setup.sh && \
    chmod +x ~/scripts/qnode_autoupdate_setup.sh && \
    sudo ~/scripts/qnode_autoupdate_setup.sh
    if [ $? -eq 0 ]; then
        echo "✅ Auto-update setup completed successfully."
        return 0
    else
        echo "❌ Failed to set up auto-update."
        return 1
    fi
}

# Function to enable auto-update
enable_autoupdate() {
    echo
    echo "⌛️ Enabling auto-update..."
    if sudo systemctl enable qnode-autoupdate.timer && sudo systemctl start qnode-autoupdate.timer; then
        echo "✅ Auto-update enabled."
        return 0
    else
        echo "❌ Failed to enable auto-update."
        return 1
    fi
}

# Function to disable auto-update
disable_autoupdate() {
    echo
    echo "⌛️ Disabling auto-update..."
    if sudo systemctl stop qnode-autoupdate.timer && sudo systemctl disable qnode-autoupdate.timer; then
        echo "✅ Auto-update disabled."
        return 0
    else
        echo "❌ Failed to disable auto-update."
        return 1
    fi
}

# Main toggle function
toggle_autoupdate() {
    local current_status=$(check_autoupdate_status)
    
    if [ "$current_status" = "OFF" ]; then
        if ! check_autoupdate_files; then
            echo "⌛️ Auto-update is not set up. Setting up now..."
            if ! setup_autoupdate; then
                echo "❌ Failed to set up auto-update. Please check your permissions and try again."
                return 1
            fi
        else
            enable_autoupdate
        fi
    else
        disable_autoupdate
    fi
    
    # Refresh status after changes
    current_status=$(check_autoupdate_status)
    echo "Auto-update is now $current_status."
}

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
        echo -e "🔴 ${RED}$component: Not installed${NC}"
    elif version_gt "$latest_version" "$current_version"; then
        echo -e "🟠 ${RED}$component: $current_version - update needed${NC}"
    else
        echo -e "🟢 $component: $current_version - up to date"
    fi
}

# Put these at the top with other functions
get_latest_node_version() {
    curl -s https://releases.quilibrium.com/release | grep -oP 'node-\K[0-9]+(\.[0-9]+){1,4}' | sort -V | tail -n 1
}

get_latest_qclient_version() {
    curl -s https://releases.quilibrium.com/qclient-release | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){1,4}' | sort -V | tail -n 1
}

get_current_node_version() {
    basename "$NODE_EXEC" | grep -oP 'node-\K[0-9]+(\.[0-9]+){1,4}(?=-|$)'
}

get_current_qclient_version() {
    basename "$QCLIENT_EXEC" | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){1,4}(?=-|$)'
}


# Function to perform a fresh check of installations and versions
fresh_check() {
    # Check node installation and version
    if [ -d "${NODE_DIR}" ]; then
        if [ -n "$NODE_EXEC" ]; then
            local current_version="$(get_current_node_version)"
            local latest_version="$(get_latest_node_version)"
            if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
                echo "Node installed: Yes"
                echo "Current Node version: $current_version"
                echo "Latest Node version: $latest_version"
            else
                echo "Node installed: Yes"
                echo "Current Node version: $current_version"
                echo "Latest Node version: Error fetching"
            fi
        else
            echo "Node installed: Yes, but no executable found"
        fi
    else
        echo "Node installed: No"
    fi

    # Check qclient installation and version
    if [ -d "${CLIENT_DIR}" ]; then
        if [ -n "$QCLIENT_EXEC" ]; then
            local current_qclient="$(get_current_qclient_version)"
            local latest_qclient="$(get_latest_qclient_version)"
            if [ $? -eq 0 ] && [ -n "$latest_qclient" ]; then
                echo "Qclient installed: Yes"
                echo "Current Qclient version: $current_qclient"
                echo "Latest Qclient version: $latest_qclient"
            else
                echo "Qclient installed: Yes"
                echo "Current Qclient version: $current_qclient"
                echo "Latest Qclient version: Error fetching"
            fi
        else
            echo "Qclient installed: Yes, but no executable found"
        fi
    else
        echo "Qclient installed: No"
    fi
}

#=====================
# Menu autoload setup
#=====================

# Function to edit .bashrc
edit_bashrc() {
    local action=$1
    local bashrc_file="$HOME/.bashrc"
    local start_marker="# === qone.sh autoload ==="
    local end_marker="# === end qone.sh autoload ==="
    
    # Get the script filename dynamically
    local script_name=$(basename "${BASH_SOURCE[0]}")
    local script_path="$HOME/$script_name"  # Construct the full path to the script

    local autoload_script=$(cat << EOF
if [ -n "\$SSH_CONNECTION" ] && [ -t 0 ] && [ "\$TERM" != "dumb" ] && [ -z "\$TMUX" ] && \
   [ -z "\$EMACS" ] && [ -z "\$VIM" ] && [ -z "\$INSIDE_EMACS" ]; then
    export Q1_MENU_SHOWN=1
    $script_path
fi
EOF
)

    if [ "$action" = "add" ]; then
        if ! grep -q "$start_marker" "$bashrc_file"; then
            echo -e "\n$start_marker\n$autoload_script\n$end_marker" >> "$bashrc_file"
        fi
    elif [ "$action" = "remove" ]; then
        sed -i "/$start_marker/,/$end_marker/d" "$bashrc_file"
    fi

    # Source .bashrc
    source "$bashrc_file"
}


# Function to set up autoload
setup_autoload() {
    edit_bashrc "add"
}

# Function to disable autoload
disable_autoload() {
    edit_bashrc "remove"
}

# Function to check autoload status
check_autoload_status() {
    if grep -q "# === qone.sh autoload ===" "$HOME/.bashrc"; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# Main function to handle menu autoload
handle_menu_autoload() {
    local current_status=$(check_autoload_status)
    
    echo
    echo "Q1 menu autoload on login"
    echo "--------------------------"
    echo -n "Current status: "
    if [ "$current_status" = "ON" ]; then
        echo "🟢 Enabled"
        read -p "Do you want to disable autoload? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            disable_autoload
            echo "✅ Menu autoload has been disabled."
            current_status="OFF"
        else
            echo "No changes made. Menu autoload remains enabled."
        fi
    else
        echo "🔴 Disabled"
        read -p "Do you want to enable autoload? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            setup_autoload
            echo "✅ Menu autoload has been enabled."
            current_status="ON"
        else
            echo "No changes made. Menu autoload remains disabled."
        fi
    fi
    
    echo
    echo "Final status:"
    echo -n "Menu autoload is now "
    if [ "$current_status" = "ON" ]; then
        echo "🟢 Enabled"
    else
        echo "🔴 Disabled"
    fi
}

#==========================
# Utility functions
#==========================

# Function to check and install a package
check_and_install() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 could not be found"
        echo "⏳ Installing $1..."
        su -c "apt install $1 -y"
    fi
}

# Handle "press any key" prompts
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

➤ Do you want to proceed? (y/n):
EOF
    read -p "> " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        $3
        return 0
    else
        # Show "press any key" message when user chooses not to proceed
        press_any_key
        return 1
    fi
}


# Function to wrap and indent text
wrap_text() {
    local text="$1"
    local indent="$2"
    echo "$text" | fold -s -w 80 | awk -v indent="$indent" '{printf "%s%s\n", indent, $0}'
}

display_temp_message() {
    if [ "$SHOW_TEMP_MESSAGE" = true ] && [ -n "$TEMP_MESSAGE" ]; then                              
        echo "──────────────────────────────────────────────────────────────────"
        echo "$TEMP_MESSAGE"                                        
        echo "──────────────────────────────────────────────────────────────────"
        echo 
    fi
}


#=====================
# Run everything
#=====================

# Initial setup
check_and_install sudo
check_and_install curl
check_for_updates
setup_aliases

read -t 0.1 -n 1000 discard  # Clear any pending input

main

if ! main; then
    echo "An error occurred while running the script."
    exit 1
fi