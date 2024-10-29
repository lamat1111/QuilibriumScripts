#!/bin/bash

# Define the version number here
SCRIPT_VERSION="1.4.2"


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
1) Check balance / address       7) Token split
2) Check individual coins        8) Token merge

3) Create transaction            9) Mint all rewards
4) Accept transaction            
5) Reject transaction            

6) Perform mutual transfer
-----------------------------------------------------------------
B) ⭐ Best server providers      X) Disclaimer                           
D) 💜 Donations                  S) Security settings
-----------------------------------------------------------------    
E) Exit

⚠️ Most Qclient commands won't work until the network is synced and stable.

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
            7) token_split; prompt_return_to_menu || break ;;
            8) token_merge; prompt_return_to_menu || break ;; 
            9) mint_all; prompt_return_to_menu || break ;;
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

mint_all() {
    echo
    echo "Mint all rewards:"
    echo "-----------------"
    echo "- This command will only work when the network is synced and stable"
    echo "- Your node must be stopped."
    echo "- You must use the public RPC. In your config.yml the 'listenGrpcMultiaddr' field must be empty"
    echo "- There is no confirmation. So once you hit enter, it will execute. It won't give you a preview of what's going to happen. So double check everything!"
    echo

    # Add confirmation prompt
    while true; do
        read -rp "Are you sure you want to proceed with minting all rewards? (Y/N): " confirm
        case $confirm in
            [Yy]* ) 
                echo "Proceeding with minting..."
                $QCLIENT_EXEC token mint all $CONFIG_FLAG
                break
                ;;
            [Nn]* ) 
                echo "Minting cancelled."
                break
                ;;
            * ) 
                echo "Please answer Y or N."
                ;;
        esac
    done
    echo
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

create_transaction() {
    echo
    echo "Creating a new transaction"
    echo "=========================="
    echo "On the current Qclient version you can only send whole coins, not 'amount' of QUIL"
    echo "So you will need the address of the coin you want to send"
    echo "You can check your coin addresses with option 2 in the menu"
    echo "You can split a coin in 2 coins with option 7."

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

    # Get and validate refund address (optional)
    while true; do
        read -p "Enter the refund address (press Enter to use your own address): " refund_address
        if [[ -z "$refund_address" ]]; then
            break
        elif [[ "$refund_address" == "$to_address" ]]; then
            echo "❌ Refund address cannot be the same as recipient address."
            continue
        elif validate_hash "$refund_address"; then
            break
        else
            echo "❌ Invalid address format. Address must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x8ae31dc9205c9031943daf4797307871fbf9ffe0851781acc694636d92756789"
            echo
        fi
    done

    # Get amount or coin ID
    echo
    echo "How would you like to make the transfer?"
    echo "1) Transfer a specific amount" - not available yet on the current Qclient version!
    echo "2) Transfer a specific coin"
    read -p "Enter your choice (1 or 2): " transfer_type

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

    # Get and validate the Pending Transaction ID
    while true; do
        read -p "Enter the transaction ID: " pending_tx_id
        if validate_hash "$pending_tx_id"; then
            break
        else
            echo "❌ Invalid transaction ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x0382e4da0c7c0133a1b53453b05096272b80c1575c6828d0211c4e371f7c81bb"
        fi
    done

    # Execute the command and display its output
    $QCLIENT_EXEC token accept "$pending_tx_id" $CONFIG_FLAG
}

reject_transaction() {
    echo
    echo "Rejecting a pending transaction"
    echo "==============================="

    # Get and validate the Pending Transaction ID
    while true; do
        read -p "Enter the transaction ID: " pending_tx_id
        if validate_hash "$pending_tx_id"; then
            break
        else
            echo "❌ Invalid transaction ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x27fff099dee515ece193d2af09b164864e4bb60c19eb6719b5bc981f92151009"
            echo
        fi
    done

    # Execute the command and display its output
    $QCLIENT_EXEC token reject "$pending_tx_id" $CONFIG_FLAG
}

mutual_transfer() {
    echo
    echo "Performing a mutual transfer"
    echo "============================"
    echo "Mutual transfers are not avilable on Qclient version 2.0.x"
    echo

    # Ask user if they are the sender or receiver
    echo "Are you the sender or receiver of this mutual transfer?"
    echo "1) Receiver"
    echo "2) Sender"
    read -p "Enter your choice (1 or 2): " role_choice

    case $role_choice in
        1) # Receiver
            echo "You are the receiver."
            read -p "Enter the expected QUIL amount (format 0.000000): " expected_amount
            
            # Validate amount is a positive number
            if [[ ! $expected_amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$expected_amount <= 0" | bc -l) -eq 1 ]]; then
                echo "❌ Invalid amount. Please enter a positive number."
                return
            fi
            
            echo
            echo "Please provide the sender with the Rendezvous ID"
            echo "and then wait for them to connect for the transaction to go through."
            echo
            $QCLIENT_EXEC token mutual-receive "$expected_amount" $CONFIG_FLAG
            ;;
            
        2) # Sender
            echo "You are the sender."
            
            # Get and validate the Rendezvous ID
            while true; do
                read -p "Enter the Rendezvous ID provided by the receiver: " rendezvous_id
                if validate_hash "$rendezvous_id"; then
                    break
                else
                    echo "❌ Invalid Rendezvous ID format. ID must start with '0x' followed by 64 hexadecimal characters."
                    echo "Example: 0x2ad567e4fc1ac335a8d3d6077de2ee998aff996b51936da04ee1b0f5dc196a4f"
                    echo
                fi
            done
            
            read -p "Enter the amount to transfer (in QUIL): " amount
            
            # Validate amount is a positive number
            if [[ ! $amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$amount <= 0" | bc -l) -eq 1 ]]; then
                echo "❌ Invalid amount. Please enter a positive number."
                return
            fi
            
            $QCLIENT_EXEC token mutual-transfer "$rendezvous_id" "$amount" $CONFIG_FLAG
            ;;
            
        *) 
            echo "❌ Invalid choice. Mutual transfer cancelled."
            return
            ;;
    esac
}

token_split() {
    echo
    echo "Token splitting"
    echo "==============="
    echo "This will split a coin into two new coins with specified amounts"
    echo
    echo "⚠️ This is very much still a BETA feature and works slowly."
    echo "The token split operation can be slow in this period of intense activity."
    echo "There is no confirmation message either after a token split :-("
    echo "But if you keep trying the split comand, it will go thorugh eventually."
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
    echo "$QCLIENT_EXEC coin split $coin_id $left_amount $right_amount $CONFIG_FLAG"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this split? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC coin split "$coin_id" "$left_amount" "$right_amount" $CONFIG_FLAG
    else
        echo "❌ Split operation cancelled."
    fi
}

token_merge() {
    echo
    echo "Token merging"
    echo "============="
    echo "This will merge two coins into a single new coin"
    echo
    echo "⚠️ This is very much still a BETA feature and works slowly."
    echo "The token merge operation can be slow in this period of intense activity."
    echo "There is no confirmation message either after a token merge :-("
    echo "But if you keep trying the merge comand, it will go thorugh eventually."
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
    echo "$QCLIENT_EXEC coin merge $left_coin $right_coin $CONFIG_FLAG"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this merge? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC coin merge "$left_coin" "$right_coin" $CONFIG_FLAG
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
# Run
#=====================

check_for_updates
add_alias_if_needed

main