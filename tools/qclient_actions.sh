#!/bin/bash

# Define the version number here
SCRIPT_VERSION="2.0.8"


#=====================
# Variables
#=====================

# Define the script path
SCRIPT_PATH=$HOME/scripts
# Or define the absolute script path by following symlinks
# SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# Qclient binary determination
QCLIENT_DIR="$HOME/ceremonyclient/client"
FLAGS="--config $HOME/ceremonyclient/node/.config --public-rpc"

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
/////////////////// QCLIENT MENU - $SCRIPT_VERSION /////////////////////
=================================================================
1) Check balance / address       7) Split coins
2) Check individual coins        8) Merge coins
3) Create transaction            9) Count coins
-----------------------------------------------------------------
S) Security settings             X) Disclaimer   
H) Help                     
----------------------------------------------------------------- 
B) ⭐ Best server providers     D) 💜 Donations 
-----------------------------------------------------------------    
E) Exit

─────────────────────────────────────────────────────────────────
➤ QCLIENT COMMANDS MAY BE SLOW IN THIS PERIOD
➤ Wait at least 60 seconds before trying again a command.
─────────────────────────────────────────────────────────────────

EOF
}


#=====================
# Helper Functions
#=====================

# Function to format titles consistently
format_title() {
    local title="$1"
    local width=${#title}
    local padding="=="
    local separator="-"
    
    # Create the top border with padding
    printf "\n=== %s ===\n" "$title"
    # Create the bottom border
    printf "%s\n" "$(printf '%*s' $((width + 8)) | tr ' ' '-')"
}

# Pre-action confirmation function
confirm_proceed() {
    local action_name="$1"
    local description="$2"
    
    echo
    echo "$(format_title "$action_name")"
    [ -n "$description" ] && echo "$description"  # Removed the \n
    echo
    
    while true; do
        read -rp "Do you want to proceed with $action_name? (y/n): " confirm
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

# wait with spinner - goes back to menu on CTRL + C
wait_with_spinner() {
    local message="${1:-Wait for %s seconds...}"
    local seconds="$2"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local pid

    message="${message//%s/"$seconds (CTRL+C to esc)"}"

    # Set up trap for SIGINT (Ctrl+C)
    trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null; echo -en "\r\033[K"; echo -e "\n\nOperation cancelled. Returning to main menu..."; main; exit 0' INT

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
    
    # Remove the trap after completion
    trap - INT
}

check_exit() {
    local input="$1"
    if [[ "$input" == "e" ]]; then
        echo "Returning to main menu..."
        main
        exit 0
    fi
    return 1
}


#=====================
# Menu functions
#=====================

prompt_return_to_menu() {
    echo
    while true; do
    echo
    echo "----------------------------------------"
        read -rp "Go back to Qclient Menu? (y/n): " choice
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
    echo "$(format_title "Token balance and account address")"
    echo
    $QCLIENT_EXEC token balance $FLAGS
    echo
}

check_coins() {
   echo
   echo "$(format_title "Individual coins")"
   echo
   tput sc
   echo "Loading your coins..."
   tput rc
   
   output=$($QCLIENT_EXEC token coins metadata $FLAGS | awk '{
     gsub("Timestamp ", "");
     frame=$(NF-2);
     ts=$NF;
     gsub("T", " ", ts);
     gsub("[+-][0-9]{2}:[0-9]{2}$", "", ts);
     cmd="date -d \""ts"\" \"+%d/%m/%Y %H.%M.%S\" 2>/dev/null";
     cmd | getline newts;
     close(cmd);
     $(NF)=newts;
     print frame, $0
   }' | sort -k1,1nr | cut -d' ' -f2- | awk -F'Frame ' '{num=substr($2,1,index($2,",")-1); print num"|"$0}' | sort -t'|' -k1nr | cut -d'|' -f2-)
   
   tput el
   echo "$output"
   echo
}

mint_all() {
    echo
    echo "$(format_title "Mint All Rewards")"
    echo "This command will mint all your available rewards."
    echo
    echo "IMPORTANT:"
    echo "- Your node must be stopped."
    echo "- You must use the public RPC. In your config.yml the 'listenGrpcMultiaddr' field must be empty"
    echo "- The process will stop by itself when it reaches increment 0 (all rewards minted)."
    echo
    echo "Steps to mint all rewards:"
    echo "- Create a tmux session"
    echo "- Execute the below command:"
    echo
    echo "$QCLIENT_EXEC token mint all $FLAGS"
    echo
}

create_transaction() {
    description="This will transfer a coin to another address.

IMPORTANT:
- Make sure the recipient address is correct - this operation cannot be undone
- The account address is different from the node peerID
- Account addresses and coin IDs have the same format - don't send to a coin address"
        
    if ! confirm_proceed "Create Transaction" "$description"; then
        return 1
    fi

    # Get and validate recipient address
    while true; do
            echo
        read -p "Enter the recipient's account address: " to_address
        check_exit "$to_address" && return 1
        if validate_hash "$to_address"; then
            break
        else
            echo "❌ Invalid address format. Address must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x7fe21cc8205c9031943daf4797307871fbf9ffe0851781acc694636d92712345"
            echo
        fi
    done

    # Get coin ID
    echo
    echo "Your current coins before transaction:"
    echo "--------------------------------------"
    check_coins
    echo
    
    while true; do
        read -p "Enter the coin ID to transfer: " coin_id
        check_exit "$coin_id" && return 1
        if validate_hash "$coin_id"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo "Example: 0x1148092cdce78c721835601ef39f9c2cd8b48b7787cbea032dd3913a4106a58d"
            echo
        fi
    done

    # Construct and show command
    cmd="$QCLIENT_EXEC token transfer $to_address $coin_id $FLAGS"
    echo
    echo "Transaction Details:"
    echo "--------------------"
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
        echo "-----------------------------"
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
    else
        echo "❌ Transaction cancelled."
    fi
}

# This one has both amount or ofcoin options, needs to be corrected
create_transaction_qclient_2.1.x() {
    echo "$(format_title "Create transaction")"
    description="This will transfer a coin to another address.

IMPORTANT:
- Make sure the recipient address is correct - this operation cannot be undone
- The account address is different from the node peerID
- Account addresses and coin IDs have the same format - don't send to a coin address"

    # Get and validate recipient address
    while true; do
        read -p "Enter the recipient's address: " to_address
        check_exit "$to_address" && return 1
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
            check_exit "$amount" && return 1
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
            echo "--------------------------------------"
            check_coins
            echo
            read -p "Enter the coin ID to transfer: " coin_id
            check_exit "$coin_id" && return 1
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
    cmd="$QCLIENT_EXEC token transfer $to_address $transfer_param $FLAGS"

    # Show transaction details for confirmation
    echo
    echo "Transaction Details:"
    echo "--------------------"
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
        echo "-----------------------------"
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Transaction cancelled."
    fi
}

token_split() {
    description="This will split a coin into two new coins with specified amounts"

    if ! confirm_proceed "Split Coins" "$description"; then
        return 1
    fi
    
    # Show current coins
    echo
    echo "Your current coins before splitting:"
    echo "------------------------------------"
    check_coins
    echo "Please select one of the above coins to split."
    echo

    # Get and validate the coin ID to split
    while true; do
        read -p "Enter the coin ID to split: " coin_id
        check_exit "$coin_id" && return 1
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
        echo
        echo "⚠️ The 2 splitted amounts must add up exactly to the coin original amount."
        echo
        read -p "Enter the amount for the first coin  (format 0.000000): " left_amount
        check_exit "$left_amount" && return 1
        if [[ ! $left_amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$left_amount <= 0" | bc -l) -eq 1 ]]; then
            echo "❌ Invalid amount. Please enter a positive number."
            continue
        fi
        break
    done

    # Get and validate the second amount
    while true; do
        read -p "Enter the amount for the second coin  (format 0.000000): " right_amount
        check_exit "$right_amount" && return 1
        if [[ ! $right_amount =~ ^[0-9]*\.?[0-9]+$ ]] || [[ $(echo "$right_amount <= 0" | bc -l) -eq 1 ]]; then
            echo "❌ Invalid amount. Please enter a positive number."
            continue
        fi
        break
    done

    # Show split details for confirmation
    echo
    echo "Split Details:"
    echo "--------------"
    echo "Original Coin: $coin_id"
    echo "First Amount: $left_amount QUIL"
    echo "Second Amount: $right_amount QUIL"
    echo
    echo "Command that will be executed:"
    echo "$QCLIENT_EXEC token split $coin_id $left_amount $right_amount $FLAGS"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this split? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC token split "$coin_id" "$left_amount" "$right_amount" $FLAGS
        
        # Show updated coins after split
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after splitting:"
        echo "---------------------------"
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Split operation cancelled."
    fi
}

token_split_advanced() {
    description="This will split a coin into multiple new coins (up to 50) using different methods"

    if ! confirm_proceed "Split Coins" "$description"; then
        return 1
    fi

    # Show split options first
    echo
    echo "Choose split method:"
    echo "1) Split in custom amounts"
    echo "2) Split in equal amounts"
    echo "3) Split by percentages"
    echo
    read -p "Enter your choice (1-3): " split_method

    case $split_method in
        [1-3])  # Valid choice, continue
            ;;
        *)  echo "❌ Invalid choice"
            return 1
            ;;
    esac

    # Now show coins and get coin selection
    echo
    echo "Your current coins:"
    echo "-----------------"
    check_coins
    echo

    # Get and validate the coin ID to split
    while true; do
        read -p "Enter the coin ID to split: " coin_id
        check_exit "$coin_id" && return 1
        if validate_hash "$coin_id"; then
            break
        else
            echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
            echo
        fi
    done

    # Get the coin amount for the selected coin
    coin_info=$($QCLIENT_EXEC token coins $FLAGS | grep "$coin_id")
    if [[ $coin_info =~ ([0-9]+\.[0-9]+)\ QUIL ]]; then
        total_amount=${BASH_REMATCH[1]}
    else
        echo "❌ Could not determine coin amount. Please try again."
        return 1
    fi

    echo
    echo "Selected coin amount: $total_amount QUIL"
    echo

    # Function to format decimal number with leading zero and trim trailing zeros
    format_decimal() {
        local num="$1"
        # Ensure leading zero
        if [[ $num =~ ^\..*$ ]]; then
            num="0$num"
        fi
        # Trim trailing zeros but maintain required decimals
        echo $num | sed 's/\.$//' | sed 's/0*$//'
    }

    case $split_method in
        1)  # Custom amounts
            while true; do
                echo
                echo "Enter amounts separated by comma (up to 100 values, must sum to $total_amount)"
                echo "Example: 1.5,2.3,0.7"
                read -p "> " amounts_input
                
                IFS=',' read -ra amounts <<< "$amounts_input"
                
                if [ ${#amounts[@]} -gt 100 ]; then
                    echo "❌ Too many values (maximum 100)"
                    continue
                fi
                
                # Calculate sum with full precision
                sum=0
                for amount in "${amounts[@]}"; do
                    if [[ ! $amount =~ ^[0-9]*\.?[0-9]+$ ]]; then
                        echo "❌ Invalid amount format: $amount"
                        continue 2
                    fi
                    sum=$(echo "scale=12; $sum + $amount" | bc)
                done
                
                # Compare with total amount (allowing for small rounding differences)
                diff=$(echo "scale=12; ($sum - $total_amount)^2 < 0.000000000001" | bc)
                if [ "$diff" -eq 1 ]; then
                    # Format amounts
                    formatted_amounts=()
                    for amount in "${amounts[@]}"; do
                        formatted_amounts+=($(format_decimal "$amount"))
                    done
                    amounts=("${formatted_amounts[@]}")
                    break
                else
                    echo "❌ Sum of amounts ($sum) does not match coin amount ($total_amount)"
                    continue
                fi
            done
            ;;
            
        2)  # Equal amounts
            while true; do
                echo
                read -p "Enter number of parts to split into (2-100): " num_parts
                if ! [[ "$num_parts" =~ ^[2-9]|[1-9][0-9]|100$ ]]; then
                    echo "❌ Please enter a number between 2 and 100"
                    continue
                fi
                
                # Calculate base amount with full precision
                base_amount=$(echo "scale=12; $total_amount / $num_parts" | bc)
                
                # Generate array of amounts
                amounts=()
                remaining=$total_amount
                
                # For all parts except the last one
                for ((i=1; i<num_parts; i++)); do
                    current_amount=$(format_decimal "$base_amount")
                    amounts+=("$current_amount")
                    remaining=$(echo "scale=12; $remaining - $current_amount" | bc)
                done
                
                # Last amount is the remaining value
                amounts+=($(format_decimal "$remaining"))
                break
            done
            ;;
            
        3)  # Percentage split
            while true; do
                echo
                echo "Enter percentages separated by comma (must sum to 100)"
                echo "Example: 50,30,20"
                read -p "> " percentages_input
                
                IFS=',' read -ra percentages <<< "$percentages_input"
                
                if [ ${#percentages[@]} -gt 100 ]; then
                    echo "❌ Too many values (maximum 100)"
                    continue
                fi
                
                # Calculate sum of percentages
                sum=0
                for pct in "${percentages[@]}"; do
                    if [[ ! $pct =~ ^[0-9]*\.?[0-9]+$ ]]; then
                        echo "❌ Invalid percentage format: $pct"
                        continue 2
                    fi
                    sum=$(echo "scale=12; $sum + $pct" | bc)
                done
                
                # Check if percentages sum to 100
                diff=$(echo "scale=12; ($sum - 100)^2 < 0.000000000001" | bc)
                if [ "$diff" -eq 1 ]; then
                    # Convert percentages to amounts
                    amounts=()
                    remaining=$total_amount
                    for ((i=0; i<${#percentages[@]}-1; i++)); do
                        amount=$(echo "scale=12; $total_amount * ${percentages[$i]} / 100" | bc)
                        formatted_amount=$(format_decimal "$amount")
                        amounts+=("$formatted_amount")
                        remaining=$(echo "scale=12; $remaining - $formatted_amount" | bc)
                    done
                    amounts+=($(format_decimal "$remaining"))
                    break
                else
                    echo "❌ Percentages must sum to 100 (current sum: $sum)"
                    continue
                fi
            done
            ;;
            
        *)  echo "❌ Invalid choice"
            return 1
            ;;
    esac

    # Construct command with all amounts
    cmd="$QCLIENT_EXEC token split $coin_id"
    for amount in "${amounts[@]}"; do
        cmd="$cmd $amount"
    done
    cmd="$cmd $FLAGS"

    # Show split details for confirmation
    echo
    echo "Split Details:"
    echo "--------------"
    echo "Original Coin: $coin_id"
    echo "Original Amount: $total_amount QUIL"
    echo "Number of parts: ${#amounts[@]}"
    echo "Split amounts:"
    for ((i=0; i<${#amounts[@]}; i++)); do
        echo "Part $((i+1)): ${amounts[$i]} QUIL"
    done
    echo
    echo "Command that will be executed:"
    echo "$cmd"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this split? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        eval "$cmd"
        
        # Show updated coins after split
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after splitting:"
        echo "---------------------------"
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
    else
        echo "❌ Split operation cancelled."
    fi
}

token_merge() {
    description="This function allows you to merge either two specific coins or all your coins into a single coin"

    if ! confirm_proceed "Merge Coins" "$description"; then
        return 1
    fi
    
    # Display merge options first
    echo
    echo "Choose merge option:"
    echo "1) Merge two specific coins"
    echo "2) Merge all coins"
    echo
    read -p "Enter your choice (1-2): " merge_choice

    case $merge_choice in
        1)  # Merge two specific coins
            echo
            echo "Your current coins before merging:"
            echo "----------------------------------"
            coins_output=$($QCLIENT_EXEC token coins $FLAGS)
            echo "$coins_output"
            echo

            # Count coins by counting lines containing "QUIL"
            coin_count=$(echo "$coins_output" | grep -c "QUIL")

            if [ "$coin_count" -lt 2 ]; then
                echo "❌ Not enough coins to merge. You need at least 2 coins."
                echo
                read -p "Press Enter to return to the main menu..."
                return 1
            fi
            
            # Get and validate the first coin ID
            while true; do
                read -p "Enter the first coin ID: " left_coin
                check_exit "$left_coin" && return 1
                if validate_hash "$left_coin"; then
                    break
                else
                    echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
                    echo
                fi
            done

            # Get and validate the second coin ID
            while true; do
                read -p "Enter the second coin ID: " right_coin
                check_exit "$right_coin" && return 1
                if validate_hash "$right_coin"; then
                    break
                else
                    echo "❌ Invalid coin ID format. ID must start with '0x' followed by 64 hexadecimal characters."
                    echo
                fi
            done

            # Show merge details and confirm
            echo
            echo "Merge Details:"
            echo "--------------"
            echo "First Coin: $left_coin"
            echo "Second Coin: $right_coin"
            echo
            echo "Command that will be executed:"
            echo "$QCLIENT_EXEC token merge $left_coin $right_coin $FLAGS"
            echo

            read -p "Do you want to proceed with this merge? (y/n): " confirm
            if [[ ${confirm,,} == "y" ]]; then
                $QCLIENT_EXEC token merge "$left_coin" "$right_coin" $FLAGS
            else
                echo "❌ Merge operation cancelled."
                return 1
            fi
            ;;

        2)  # Merge all coins
            # Verify we have enough coins to merge
            coin_count=$($QCLIENT_EXEC token coins $FLAGS | grep -c "QUIL")
            
            if [ "$coin_count" -lt 2 ]; then
                echo "❌ Not enough coins to merge. You need at least 2 coins."
                echo
                read -p "Press Enter to return to the main menu..."
                return 1
            fi

            # Show command and confirm
            echo "Command that will be executed:"
            echo "$QCLIENT_EXEC token merge all $FLAGS"
            echo
            
            read -p "Do you want to proceed with merging all coins? (y/n): " confirm
            if [[ ${confirm,,} == "y" ]]; then
                $QCLIENT_EXEC token merge all $FLAGS
            else
                echo "❌ Merge operation cancelled."
                return 1
            fi
            ;;

        *)  echo "❌ Invalid choice"
            return 1
            ;;
    esac

    # Show updated coins after merge
    echo
    wait_with_spinner "Showing your coins in %s secs..." 30
    echo
    echo "Your coins after merging:"
    echo "-------------------------"
    check_coins
    echo
    echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
    echo "If still nothing changes, you may want to try to execute the operation again."
}

token_merge_simple() {
    description="This will merge two coins into a single new coin"

    if ! confirm_proceed "Merge Coins" "$description"; then
        return 1
    fi
    
    # Show current coins
    echo
    echo "Your current coins before merging:"
    echo "----------------------------------"
    check_coins
    echo "Please select two of the above coins to merge."
    echo
    
    # Get and validate the first coin ID
    while true; do
        read -p "Enter the first coin ID: " left_coin
        check_exit "$left_coin" && return 1
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
        check_exit "$right_coin" && return 1
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
    echo "--------------"
    echo "First Coin: $left_coin"
    echo "Second Coin: $right_coin"
    echo
    echo "Command that will be executed:"
    echo "$QCLIENT_EXEC token merge $left_coin $right_coin $FLAGS"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed with this merge? (y/n): " confirm

    if [[ ${confirm,,} == "y" ]]; then
        $QCLIENT_EXEC token merge "$left_coin" "$right_coin" $FLAGS
        
        # Show updated coins after merge
        echo
        wait_with_spinner "Showing your coins in %s secs..." 30
        echo
        echo "Your coins after merging:"
        echo "-------------------------"
        check_coins
        echo
        echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
        echo "If still nothing changes, you may want to try to execute the operation again."
    else
        echo "❌ Merge operation cancelled."
    fi
}

token_merge_all() {
    description="This will merge all your coins into a single coin."

    if ! confirm_proceed "Merge All Coins" "$description"; then
        return 1
    fi

    echo "Current coins that will be merged:"
    echo "---------------------------------"
    coins_output=$($QCLIENT_EXEC token coins $FLAGS)
    echo "$coins_output"
    echo

    # Count coins by counting lines containing "QUIL"
    coin_count=$(echo "$coins_output" | grep -c "QUIL")

    if [ "$coin_count" -lt 2 ]; then
        echo "❌ Not enough coins to merge. You need at least 2 coins."
        echo
        read -p "Press Enter to return to the main menu..."
        return 1
    fi

    # Extract coin values and calculate total
    total_value=0
    while read -r line; do
        if [[ $line =~ ([0-9]+\.[0-9]+)\ QUIL ]]; then
            value=${BASH_REMATCH[1]}
            total_value=$(echo "$total_value + $value" | bc)
        fi
    done <<< "$coins_output"

    echo "Found $coin_count coins to merge"
    echo "Total amount in QUIL will be $total_value"
    echo

    # Ask for confirmation
    read -p "Do you want to proceed? (y/n): " confirm
    if [[ ${confirm,,} != "y" ]]; then
        echo "❌ Operation cancelled."
        return 1
    fi

    echo
    $QCLIENT_EXEC token merge all $FLAGS

    # Show updated coins after merge
    echo
    wait_with_spinner "Showing your coins in %s secs..." 30
    echo
    echo "Your coins after merging:"
    echo "-------------------------"
    check_coins
    echo
    echo "If you don't see the changes yet, wait a moment and check your coins again from the main menu."
    echo "If still nothing changes, you may want to try to execute the operation again."
}

count_coins() {
    echo
    echo "$(format_title "Count Coins")"
    
    # Run the coins command and capture output silently
    coins_output=$($QCLIENT_EXEC token coins $FLAGS)
    
    # Count coins by counting lines containing "QUIL"
    coin_count=$(echo "$coins_output" | grep -c "QUIL")
    
    # Calculate total value
    total_value=0
    while read -r line; do
        if [[ $line =~ ([0-9]+\.[0-9]+)\ QUIL ]]; then
            value=${BASH_REMATCH[1]}
            total_value=$(echo "$total_value + $value" | bc)
        fi
    done <<< "$coins_output"
    
    echo "You currently have $coin_count coins"
    echo "Total value: $total_value QUIL"
    echo
}

help() {
    echo
    $QCLIENT_EXEC --help
    echo
}

donations() {
    echo
    echo "$(format_title "Donations")"
    echo '
Quilbrium.one is a one-man volunteer effort.
If you would like to chip in some financial help, thank you!

You can send native QUIL at this address:
0x0e15a09539c95784c8d7e1b80beb175f12967764daa7d19626cc526575483180

You can send ERC-20 tokens at this address:
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013

Or visit this page: https://iri.quest/q-donations
'
}

disclaimer() {
    echo
    echo "$(format_title "Disclaimer")"
    echo '
This tool and all related scripts are unofficial and are being shared as-is.
I take no responsibility for potential bugs or any misuse of the available options. 

All scripts are open source; feel free to inspect them before use.
Repo: https://github.com/lamat1111/QuilibriumScripts
'
}

best_providers() {
    echo
    echo "$(format_title "Best Server Providers")"
    echo '
Check out the best server providers for your node
at ★ https://iri.quest/q-best-providers ★

Avoid using providers that specifically ban crypto and mining.
'
}

security_settings() {
    echo
    echo "$(format_title "Security Settings")"
    echo '
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

ALIAS_MARKER_FILE="$SCRIPT_DIR/.quilclient_menu_alias_added"

add_alias_if_needed() {
    if [ ! -f "$ALIAS_MARKER_FILE" ]; then
        local comment_line="# This alias calls the \"qclient menu\" by typing \"quilclient\""
        local alias_line="alias quilclient='$HOME/scripts/qclient_actions.sh'"  # Hardcoded path
        if ! grep -q "$alias_line" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"  # Add a blank line for better readability
            echo "$comment_line" >> "$HOME/.bashrc"
            echo "$alias_line" >> "$HOME/.bashrc"
            echo "Alias added to .bashrc."
            
            # Source .bashrc to make the alias immediately available
            if [ -n "$BASH_VERSION" ]; then
                source "$HOME/.bashrc"
                echo "Alias 'quilclient' is now active."
            else
                echo "Please run 'source ~/.bashrc' or restart your terminal to use the 'quilclient' command."
            fi
        fi
        touch "$ALIAS_MARKER_FILE"
    fi
}


migrate_old_alias() {
    # Only proceed if the old marker file exists
    if [ -f "$SCRIPT_DIR/.qclient_actions_alias_added" ]; then
        # Check if old alias exists
        if grep -q "alias qclient=" "$HOME/.bashrc"; then
            # Remove the old alias and its comment - using more flexible patterns
            sed -i '/^#.*qclient menu.*typing.*qclient/d' "$HOME/.bashrc"
            sed -i '/^alias.*qclient=.*scripts.*qclient_actions.sh/d' "$HOME/.bashrc"
            
            # Add the new alias
            echo "" >> "$HOME/.bashrc"  # Add a blank line for readability
            echo "# This alias calls the \"qclient menu\" by typing \"quilclient\"" >> "$HOME/.bashrc"
            echo "alias quilclient='$HOME/scripts/qclient_actions.sh'" >> "$HOME/.bashrc"
            
            # Source bashrc to apply changes
            if [ -n "$BASH_VERSION" ]; then
                source "$HOME/.bashrc"
                echo "Alias migrated from 'qclient' to 'quilclient'"
            else
                echo "Please run 'source ~/.bashrc' or restart your terminal to use the new 'quilclient' alias"
            fi
            
            # Remove the old marker file and create the new one
            rm "$SCRIPT_DIR/.qclient_actions_alias_added"
            touch "$SCRIPT_DIR/.quilclient_menu_alias_added"
        fi
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
            7) token_split_advanced && prompt_return_to_menu || break;;
            8) token_merge && prompt_return_to_menu || break ;;
            9) count_coins && prompt_return_to_menu || break ;;
            #9) mint_all && prompt_return_to_menu || break ;;
            [sS]) security_settings; press_any_key ;;
            [bB]) best_providers; press_any_key ;;
            [dD]) donations; press_any_key ;;
            [xX]) disclaimer; press_any_key ;;
            [hH]) help; press_any_key ;;
            [eE]) echo; break ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}


#=====================
# Run
#=====================

check_for_updates
migrate_old_alias
add_alias_if_needed

main