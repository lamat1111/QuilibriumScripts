#!/bin/bash

# Define the version number here
SCRIPT_VERSION="1.4.5"


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

3) Create transaction            9) Mint all rewards
-----------------------------------------------------------------
B) ⭐ Best server providers      X) Disclaimer                           
D) 💜 Donations                  S) Security settings
-----------------------------------------------------------------    
E) Exit

⚠️ Most Qclient commands won't work until the network is synced and stable.

EOF
}


#=====================
# Helper Functions
#=====================

# Pre-action confirmation function
confirm_proceed() {
    local action_name="$1"
    local description="$2"
    local warning_message="$3"
    
    echo
    echo "$action_name:"
    echo "$(printf '%*s' "${#action_name}" | tr ' ' '-')"  # Create a line of dashes matching the title length
    echo "$description"
    echo
    echo "$warning_message"
    echo
    
    while true; do
        read -rp "Do you want to proceed with $action_name? (Y/N): " confirm
        case $confirm in
            [Yy]* ) 
                return 0  # User confirmed
                ;;
            [Nn]* ) 
                echo "Operation cancelled."
                display_menu
                return 1  # User cancelled
                ;;
            * ) 
                echo "Please answer Y or N."
                ;;
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
    warning_message="- This command will only work when the network is synced and stable
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
    echo "1) Transfer a specific amount - not available yet on the current Qclient version!"
    echo "2) Transfer a specific coin"
    read -p "Enter your choice (1 or 2): " transfer_type

    if [[ $transfer_type == "1" ]]; then