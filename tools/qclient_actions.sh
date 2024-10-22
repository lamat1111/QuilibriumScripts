#!/bin/bash

# Define the version number here
SCRIPT_VERSION="1.2.5"

# Define the script path
SCRIPT_PATH="${BASH_SOURCE[0]}"

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
1) Check balance / address
2) Check individual coins

3) Create transaction
4) Accept transaction
5) Reject transaction

6) Perform mutual transfer
-----------------------------------------------------------------
B) ⭐ Best server providers     X) Disclaimer                           
D) 💜 Donations                 S) Security settings
-----------------------------------------------------------------    
E) Exit

EOF
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

create_transaction() {
    echo
    echo "Creating a new transaction"
    echo "=========================="

    # Get recipient address
    read -p "Enter the recipient's address: " to_address

    # Get refund address (optional)
    read -p "Enter the refund address (press Enter to use your own address): " refund_address

    # Get amount or coin ID
    read -p "Do you want to transfer a specific amount (A) or use a specific coin (C)? " transfer_type

    if [[ $transfer_type == "A" || $transfer_type == "a" ]]; then
        read -p "Enter the amount to transfer (in QUIL): " amount
        transfer_param="$amount"
    elif [[ $transfer_type == "C" || $transfer_type == "c" ]]; then
        read -p "Enter the coin ID to transfer: " coin_id
        transfer_param="$coin_id"
    else
        echo "❌ Invalid option. Aborting transaction creation."
        return
    fi

    # Construct the command
    if [[ -z "$refund_address" ]]; then
        cmd="$QCLIENT_EXEC token transfer $to_address $transfer_param $CONFIG_FLAG"
    else
        cmd="$QCLIENT_EXEC token transfer $to_address $refund_address $transfer_param $CONFIG_FLAG"
    fi

    # Show transaction details for confirmation
    echo
    echo "Transaction Details:"
    echo "===================="
    echo "Recipient: $to_address"
    echo "Refund Address: ${refund_address:-"(Your own address)"}"
    if [[ $transfer_type == "A" || $transfer_type == "a" ]]; then
        echo "Amount: $amount QUIL"
    else
        echo "Coin ID: $coin_id"
    fi
    echo
    echo "Command to be executed:"
    echo "$cmd"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this transaction? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        echo "✅ Executing transaction..."
        eval "$cmd"
        echo
        echo "⚠️ Important: This transaction is pending."
        echo "The receiver needs to accept it for the transfer to complete."
        echo "Please provide the receiver with the Pending Transaction ID"
        echo "from the command response above."
    else
        echo "❌ Transaction cancelled."
    fi
}

accept_transaction() {
    echo
    echo "Accepting a pending transaction"
    echo "==============================="

    # Prompt for the Pending Transaction ID
    read -p "Enter the transaction ID: " pending_tx_id

    # Execute the command and display its output
    $QCLIENT_EXEC token accept "$pending_tx_id" $CONFIG_FLAG
}

reject_transaction() {
    echo
    echo "Rejecting a pending transaction"
    echo "==============================="

    # Prompt for the Pending Transaction ID
    read -p "Enter the transaction ID: " pending_tx_id

    # Execute the command and display its output
    $QCLIENT_EXEC token reject "$pending_tx_id" $CONFIG_FLAG
}

mutual_transfer() {
    echo
    echo "Performing a mutual transfer"
    echo "============================"

    # Ask user if they are the sender or receiver
    echo "Are you the sender or receiver of this mutual transfer?"
    echo "1) Receiver"
    echo "2) Sender"
    read -p "Enter your choice (1 or 2): " role_choice

    case $role_choice in
        1) # Receiver
            echo "You are the receiver."
            read -p "Enter the expected amount (in QUIL): " expected_amount
            echo
            echo "Please provide the sender with the Rendezvous ID"
            echo "and then wait for them to connect for the transaction to go through."
            echo
            echo "Executing mutual receive command..."
            $QCLIENT_EXEC token mutual-receive "$expected_amount" $CONFIG_FLAG
            ;;
            
        2) # Sender
            echo "You are the sender."
            read -p "Enter the Rendezvous ID provided by the receiver: " rendezvous_id
            read -p "Enter the amount to transfer (in QUIL): " amount
            echo "Executing mutual transfer command..."
            $QCLIENT_EXEC token mutual-transfer "$rendezvous_id" "$amount" $CONFIG_FLAG
            ;;
            
        *) 
            echo "Invalid choice. Mutual transfer cancelled."
            return
            ;;
    esac
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
cat "'$SCRIPT_PATH'"

The script also auto-updates to the latest version automatically.
If you want to disable auto-updates, comment out the line "check_for_updates"
in the script itself.

DISCLAIMER:
The author assumes no responsibility for any QUIL loss due to misuse of this script.
Use this script at your own risk and always verify transactions before confirming them.
'
}

#=====================
# Qclient binary determination
#=====================

QCLIENT_DIR="$HOME/ceremonyclient/client"
CONFIG_FLAG="--config $HOME/ceremonyclient/node/.config"

QCLIENT_EXEC=$(find "$QCLIENT_DIR" -name "qclient-*-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" -type f -executable | sort -V | tail -n1)

if [ -z "$QCLIENT_EXEC" ]; then
    echo "❌ No matching qclient binary found in $QCLIENT_DIR"
    exit 1
fi


#=====================
# One-time alias setup
#=====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIAS_MARKER_FILE="$SCRIPT_DIR/.qclient_actions_alias_added"

add_alias_if_needed() {
    if [ ! -f "$ALIAS_MARKER_FILE" ]; then
        local comment_line="# This alias calls the \"qclient actions\" menu by typing \"qclient\""
        local alias_line="alias qclient='$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")'"
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
# Run
#=====================

check_for_updates
add_alias_if_needed

main