#!/bin/bash

# Define the version number here
SCRIPT_VERSION="1.6.0"


#=====================
# Variables
#=====================

# Define the script path
SCRIPT_PATH=$HOME/scripts
# Or define the absolute script path by following symlinks
# SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# Qclient binary determination
QCLIENT_DIR="$HOME/ceremonyclient/client"
CONFIG_FLAG="--config $HOME/ceremonyclient/node/.config"

QCLIENT_EXEC=$(find "$QCLIENT_DIR" -name "qclient-*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)

if [ -z "$QCLIENT_EXEC" ]; then
    echo "❌ No matching qclient binary found in $QCLIENT_DIR"
    exit 1
fi


#=====================
# Menu interface
#=====================

display_menu() {
    clear
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

=================================================================
/////////////////// QCLIENT ACTIONS - $SCRIPT_VERSION /////////////////////
=================================================================
               ⚠️ This menu is still in BETA ⚠️
              only test with small amounts first
          read the 'Disclaimer' and 'Security Settings'
-----------------------------------------------------------------
1) Check balance / address       7) Coin split
2) Check individual coins        8) Coin merge

3) Create transaction            9) Mint all rewards (UNTESTED)
-----------------------------------------------------------------
B) ⭐ Best server providers      X) Disclaimer                           
D) 💜 Donations                  S) Security settings
-----------------------------------------------------------------    
E) Exit

⚠️ QCLIENT COMMANDS MAY BE SLOW DURING THIS PERIOD OF INTENSE ACTIVITY ⚠️

Most Qclient commands won't work if you use the local RPC at the moment.
Set your config.yml to use the public RPC if you haven't done so already.
You can use option 3 in the Q1 menu to so it.

Even with the public RPC enabled, token operations may not go through immediately,
wait at least 60 seconds before trying again a command.

EOF
}


#=====================
# Helper Functions
#=====================

# Pre-action confirmation function
confirm_proceed() {
    local action_name="$1"
    local description="$2"
    local warning_message="${3:-}"  # Use parameter expansion to handle optional warning
    
    echo
    echo "$action_name:"
    echo "$(printf '%*s' "${#action_name}" | tr ' ' '-')"
    [ -n "$description" ] && echo "$description"
    [ -n "$warning_message" ] && echo -e "\n$warning_message"
    echo
    
    while true; do
        read -rp "Do you want to proceed with $action_name? (Y/N): " confirm
        case $confirm in
            [Yy]* ) return 0 ;;
            [Nn]* ) 
                echo "Operation cancelled."
                display_menu
                return 1 ;;
            * ) echo "Please answer Y or N." ;;
        esac
    done
}

# Function to validate Quilibrium hashes (addresses, transaction IDs, etc)
validate_hash() {
    local hash="$1"
    local hash_regex="^0x[0-9a-fA-F]{64}$"
    
    if [[ ! $hash =~ $hash_regex ]]; then
        return 1
    fi
    return 0
}

wait_with_spinner() {
    local message="${1:-Wait for %s seconds...}"
    local seconds="$2"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local pid

    message="${message//%s/$seconds}"

    (
        while true; do
            for (( i=0; i<${#chars}; i++ )); do
                echo -en "\r$message ${chars:$i:1} "
                sleep 0.1
            done
        done
    ) &
    pid=$!

    sleep "$seconds"
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
    echo -en "\r\033[K"
}

#=====================
# Menu functions
#=====================

prompt_return_to_menu() {
    echo
    while true; do
    echo
    echo "--------------------------------------"
        read -rp "Go back to Qclient Actions menu? (Y/N): " choice
        case $choice in
            [Yy]* ) return 0 ;;  # Return true (0) to continue the loop
            [Nn]* ) return 1 ;;  # Return false (1) to break the loop
            * ) echo "Please answer Y or N." ;;
        esac
    done
}

# Handle "press any key" prompts
press_any_key() {
    echo
    read -n 1 -s -r -p "Press any key to continue..."
    echo
    display_menu
}

check_balance() {
    echo
    echo "Token balance and account address:"
    echo
    $QCLIENT_EXEC token balance $CONFIG_FLAG
    echo
}

check_coins() {
    echo
    echo "Individual coins:"
    echo
    $QCLIENT_EXEC token coins $CONFIG_FLAG
    echo
}

mint_all() {
    description="This will mint all your available rewards"
    warning_message="- This command has not been tested yet so it is better if you execute it by yourself and not via the menu option
- Execute it inside a tmux session so you can logout of your machine and check back later, 
  as the command will take a long time to mint all your increments. 
  It will stop by itself when it reaches increment 0.

IMPORTANT:
- Your node must be stopped.
- You must use the public RPC. In your config.yml the 'listenGrpcMultiaddr' field must be empty
- There is no confirmation. So once you hit enter, it will execute. It won't give you a preview of what's going to happen. So double check everything!"

    if ! confirm_proceed "minting all rewards" "$description" "$warning_message"; then
        return 1
    fi

    echo "Proceeding with minting..."
    $QCLIENT_EXEC token mint all $CONFIG_FLAG
}

create_transaction() {
    # Pre-action confirmation
    description="This will transfer a coin to another address"
    warning="⚠️ Make sure the recipient address is correct. This operation cannot be undone!
    ⚠️ The account address is different from the node peerID!
    ⚠️ Account addresses and coin IDs have the same format, so be sure to not send a coin to another coin address!"
        
    if ! confirm_proceed "coin transfer" "$description" "$warning"; then
        return 1
    fi

    # Get and validate recipient address
    while true; do
        read -p "Enter the recipient's account address: " to_address
        if validate_hash "$to_address"; then
            break
        else
            echo "❌ Invalid address format. Address must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x7fe21cc8205c9031943daf4797307871fbf9ffe0851781acc694636d92712345"
            echo
        fi
    done

    # Get coin ID
    echo "Your current coins before transaction:"
    echo "======================================"
    check_coins
    echo
    
    while true; do
        read -p "Enter the coin ID to transfer: " coin_id
        if validate_hash "$coin_id"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x1148092cdce78c721835601ef39f9c2cd8b48b7787cbea032dd3913a4106a58d"
            echo
        fi
    done

    # Construct and show command
    cmd="$QCLIENT_EXEC token transfer $to_address $coin_id $CONFIG_FLAG"
    echo
    echo "Transaction Details:"
    echo "===================="
    echo "Recipient: $to_address"
    echo "Coin ID: $coin_id"
    echo
    echo "Command that will be executed:"
    echo "$cmd"
    echo

    read -p "Do you want to proceed with this transaction? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        eval "$cmd"
        echo
        echo "Transaction sent. The receiver does not need to accept it."
        
        wait_with_spinner "Checking updated coins in %s seconds..." 30
        echo
        echo "Your coins after transaction:"
        echo "============================="
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
    else
        echo "❌ Transaction cancelled."
    fi
}

# This one has both amount or ofcoin options, needs to be corrected
create_transaction_qclient_2.1.x() {
    echo
    echo "Creating a new transaction"
    echo "=========================="
    echo "- On the current Qclient version you can only send whole coins, not 'amount' of QUIL"
    echo "- You will need the address (ID) of the coin you want to send."
    echo "- You can split a coin in 2 coins with option 7."
    echo

    # Get and validate recipient address
    while true; do
        read -p "Enter the recipient's address: " to_address
        if validate_hash "$to_address"; then
            break
        else
            echo "❌ Invalid address format. Address must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x7fe21cc8205c9031943daf4797307871fbf9ffe0851781acc694636d92712345"
            echo
        fi
    done

    # Get amount or coin ID
    echo
    echo "How would you like to make the transfer?"
    echo "1) Transfer a specific amount - not available yet in the current Qclient version!"
    echo "2) Transfer a specific coin"
    read -p "Enter your choice (only 2 is available): " transfer_type

    if [[ $transfer_type == "1" ]]; then
        while true; do
            echo
            read -p "Enter the QUIL amount to transfer (format 0.000000): " amount
            # Validate amount is a positive number
            if [[ ! $amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$amount <= 0" | bc -l) -eq 1 ]]; then
                echo "❌ Invalid amount. Please enter a positive number."
                continue
            fi
            transfer_param="$amount"
            break
        done
    elif [[ $transfer_type == "2" ]]; then
        while true; do
            # Show current coins before transaction
            echo "Your current coins before transaction:"
            echo "======================================"
            check_coins
            echo
            read -p "Enter the coin ID to transfer: " coin_id
            if validate_hash "$coin_id"; then
                break
            else
                echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
                echo "Example: 0x1148092cdce78c721835601ef39f9c2cd8b48b7787cbea032dd3913a4106a58d"
                echo
            fi
        done
        transfer_param="$coin_id"
    else
        echo "❌ Invalid option. Aborting transaction creation."
        return
    fi

    # Construct the command
    cmd="$QCLIENT_EXEC token transfer $to_address $transfer_param $CONFIG_FLAG"

    # Show transaction details for confirmation
    echo
    echo "Transaction Details:"
    echo "===================="
    echo "Recipient: $to_address"
    if [[ $transfer_type == "1" ]]; then
        echo "Amount: $amount QUIL"
    else
        echo "Coin ID: $coin_id"
    fi
    echo
    echo "Command that will be executed:"
    echo "$cmd"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this transaction? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        eval "$cmd"
        echo
        echo "Currently there is no transaction ID, and the receiver does not have to accept the transaction."
        echo "Unless you received an error, your transaction should be already on its way to the receiver."
        
        # Show updated coins after transaction
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after transaction:"
        echo "============================="
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Transaction cancelled."
    fi
}

token_split() {
    # Pre-action confirmation
    description="This will split a coin into two new coins with specified amounts"

    if ! confirm_proceed "token splitting" "$description"; then
        return 1
    fi
    
    # Show current coins
    echo
    echo "Your current coins before splitting:"
    echo "=================================="
    check_coins
    echo "Please select one of the above coins to split."
    echo

    # Get and validate the coin ID to split
    while true; do
        read -p "Enter the coin ID to split: " coin_id
        if validate_hash "$coin_id"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x1148092cdce78c721835601ef39f9c2cd8b48b7787cbea032dd3913a4106a58d"
            echo
        fi
    done

    # Get and validate the first amount
    while true; do
        read -p "Enter the amount for the first coin  (format 0.000000): " left_amount
        if [[ ! $left_amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$left_amount <= 0" | bc -l) -eq 1 ]]; then
            echo "❌ Invalid amount. Please enter a positive number."
            continue
        fi
        break
    done

    # Get and validate the second amount
    while true; do
        read -p "Enter the amount for the second coin  (format 0.000000): " right_amount
        if [[ ! $right_amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$right_amount <= 0" | bc -l) -eq 1 ]]; then
            echo "❌ Invalid amount. Please enter a positive number."
            continue
        fi
        break
    done

    # Show split details for confirmation
    echo
    echo "Split Details:"
    echo "=============="
    echo "Original Coin: $coin_id"
    echo "First Amount: $left_amount QUIL"
    echo "Second Amount: $right_amount QUIL"
    echo
    echo "Command that will be executed:"
    echo "$QCLIENT_EXEC token split $coin_id $left_amount $right_amount $CONFIG_FLAG"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this split? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC token split "$coin_id" "$left_amount" "$right_amount" $CONFIG_FLAG
        
        # Show updated coins after split
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after splitting:"
        echo "==========================="
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Split operation cancelled."
    fi
}

token_merge() {
    # Pre-action confirmation
    description="This will merge two coins into a single new coin"

    if ! confirm_proceed "token merging" "$description"; then
        return 1
    fi
    
    # Show current coins
    echo
    echo "Your current coins before merging:"
    echo "================================"
    check_coins
    echo "Please select two of the above coins to merge."
    echo
    
    # Get and validate the first coin ID
    while true; do
        read -p "Enter the first coin ID: " left_coin
        if validate_hash "$left_coin"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x1148092cdce78c721835601ef39f9c2cd8b48b7787cbea032dd3913a4106a58d"
            echo
        fi
    done

    # Get and validate the second coin ID
    while true; do
        read -p "Enter the second coin ID: " right_coin
        if validate_hash "$right_coin"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x0140e01731256793bba03914f3844d645fbece26553acdea8ac4de4d84f91690"
            echo
        fi
    done

    # Show merge details for confirmation
    echo
    echo "Merge Details:"
    echo "=============="
    echo "First Coin: $left_coin"
    echo "Second Coin: $right_coin"
    echo
    echo "Command that will be executed:"
    echo "$QCLIENT_EXEC token merge $left_coin $right_coin $CONFIG_FLAG"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this merge? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC token merge "$left_coin" "$right_coin" $CONFIG_FLAG
        
        # Show updated coins after merge
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after merging:"
        echo "========================="
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Merge operation cancelled."
    fi
}

donations() {
    echo '

Donations
=========

Quilbrium.one is a one-man volunteer effort.
If you would like to chip in some financial help, thank you!

You can send ERC-20 tokens at this address:
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013

Or visit this page: https://iri.quest/q-donations
'
}

disclaimer() {
    echo '

Disclaimer
==========

This tool and all related scripts are unofficial and are being shared as-is.
I take no responsibility for potential bugs or any misuse of the available options. 

All scripts are open source; feel free to inspect them before use.
Repo: https://github.com/lamat1111/QuilibriumScripts
'
}

best_providers() {
    echo '

Best Server Providers
====================

Check out the best server providers for your node
at ★ https://iri.quest/q-best-providers ★

Avoid using providers that specifically ban crypto and mining.
'
}

security_settings() {
    echo '

Security Settings
================

This script performs QUIL transactions. You can inspect the source code by running:
cat "'$SCRIPT_PATH/qclient_actions.sh'"

The script also auto-updates to the latest version automatically.
If you want to disable auto-updates, comment out the line "check_for_updates"
in the script itself.

DISCLAIMER:
The author assumes no responsibility for any QUIL loss due to misuse of this script.
Use this script at your own risk and always verify transactions before confirming them.
'
}


#=====================
# One-time alias setup
#=====================

# Replace the current SCRIPT_DIR definition with:
SCRIPT_DIR="$HOME/scripts"  # Hardcoded path
# Or use this more dynamic approach that follows symlinks:
#SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

ALIAS_MARKER_FILE="$SCRIPT_DIR/.qclient_actions_alias_added"

add_alias_if_needed() {
    if [ ! -f "$ALIAS_MARKER_FILE" ]; then
        local comment_line="# This alias calls the \"qclient actions\" menu by typing \"qclient\""
        local alias_line="alias qclient='/root/scripts/$(basename "${BASH_SOURCE[0]}")'"  # Hardcoded path
        if ! grep -q "$alias_line" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"  # Add a blank line for better readability
            echo "$comment_line" >> "$HOME/.bashrc"
            echo "$alias_line" >> "$HOME/.bashrc"
            echo "Alias added to .bashrc."
            
            # Source .bashrc to make the alias immediately available
            if [ -n "$BASH_VERSION" ]; then
                source "$HOME/.bashrc"
                echo "Alias 'qclient' is now active."
            else
                echo "Please run 'source ~/.bashrc' or restart your terminal to use the 'qclient' command."
            fi
        fi
        touch "$ALIAS_MARKER_FILE"
    fi
}


#=====================
# Check for updates
#=====================

check_for_updates() {
    if ! command -v curl &> /dev/null; then
        return 1
    fi

    local GITHUB_RAW_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qclient_actions.sh"
    local LATEST_VERSION

    LATEST_VERSION=$(curl -sS "$GITHUB_RAW_URL" | sed -n 's/^SCRIPT_VERSION="\(.*\)"$/\1/p')
    
    if [ $? -ne 0 ] || [ -z "$LATEST_VERSION" ]; then
        return 1
    fi
    
    # Version comparison function
    version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
    
    if version_gt "$LATEST_VERSION" "$SCRIPT_VERSION"; then
        if curl -sS -o "$HOME/scripts/qclient_actions_new.sh" "$GITHUB_RAW_URL"; then
            chmod +x "$HOME/scripts/qclient_actions_new.sh"
            mv "$HOME/scripts/qclient_actions_new.sh" "$HOME/scripts/qclient_actions.sh"
            exec "$HOME/scripts/qclient_actions.sh"
        fi
    fi
}


#=====================
# Main Menu Loop
#=====================

main() {
    while true; do
        display_menu
        
        read -rp "Enter your choice: " choice
        
        case $choice in
            1) check_balance; prompt_return_to_menu || break ;;
            2) check_coins; prompt_return_to_menu || break ;;
            3) create_transaction; prompt_return_to_menu || break ;;
            4) accept_transaction; prompt_return_to_menu || break ;;
            5) reject_transaction; prompt_return_to_menu || break ;;
            6) mutual_transfer; prompt_return_to_menu || break ;;
            7) token_split && prompt_return_to_menu || continue ;; # Modified to handle the return
            8) token_merge && prompt_return_to_menu || continue ;; # Modified to handle the return
            9) mint_all && prompt_return_to_menu || continue ;; # Modified to handle the return
            [sS]) security_settings; press_any_key || break ;;
            [bB]) best_providers; press_any_key || break ;;
            [dD]) donations; press_any_key || break ;;
            [xX]) disclaimer; press_any_key || break ;;
            [eE]) echo ; break ;;
            *) echo "Invalid option, please try again."; prompt_return_to_menu || break ;;
        esac
    done

    echo
}


#=====================
# Run
#=====================

check_for_updates
add_alias_if_needed

main