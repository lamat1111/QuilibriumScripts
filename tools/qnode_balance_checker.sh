#!/bin/bash

# Set timezone to Europe/Rome
export TZ="Europe/Rome"

# Script version
SCRIPT_VERSION="1.6.0"

# Function to check for newer script version
check_for_updates() {
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/scripts/qnode_balance_checker.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh"
        chmod +x ~/scripts/qnode_balance_checker.sh
        sleep 1
    fi
}

# Check for updates and update if available
check_for_updates

# Function to get the node binary name
get_node_binary() {
    local node_dir="$HOME/ceremonyclient/node"
    local binary_name
    binary_name=$(find "$node_dir" -name "node-[0-9]*" ! -name "*.dgst*" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1 | xargs basename)
    
    if [ -z "$binary_name" ]; then
        echo "ERROR: No executable node binary found in $node_dir"
        return 1
    fi
    
    echo "$binary_name"
}

# Function to get the unclaimed balance
get_unclaimed_balance() {
    local node_directory="$HOME/ceremonyclient/node"
    local NODE_BINARY
    NODE_BINARY=$(get_node_binary)
    
    if [ "$NODE_BINARY" == "ERROR:"* ]; then
        echo "ERROR"
        return 1
    fi
    
    local node_command="./$NODE_BINARY -balance"
    
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    
    local balance
    balance=$(echo "$output" | grep "Owned balance" | awk '{print $3}' | sed 's/QUIL//g' | tr -d ' ')
    
    if [[ "$balance" =~ ^[0-9.]+$ ]]; then
        echo "$balance"
    else
        echo "ERROR"
    fi
}

write_to_csv() {
    local filename="$HOME/scripts/balance_log.csv"
    local data="$1"
    
    if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
        echo "time,balance" > "$filename"
    fi
    
    # Split the data into time and balance
    local time=$(echo "$data" | cut -d',' -f1)
    local balance=$(echo "$data" | cut -d',' -f2)
    
    # Only process if balance is not an error
    if [ "$balance" != "ERROR" ]; then
        # Clean the balance input:
        # 1. Remove any existing commas
        # 2. Ensure decimal point is a dot
        # 3. Remove any whitespace
        balance=$(echo "$balance" | tr ',' '.' | sed 's/[[:space:]]//g')
        
        # Verify if the balance is a valid number
        if ! echo "$balance" | grep -E '^[0-9]+\.?[0-9]*$' > /dev/null; then
            echo "❌ Error: Invalid number format: $balance"
            exit 1
        fi
        
        # Replace dot with comma for CSV format
        #balance=$(echo "$balance" | sed 's/\./,/')
        
        # Format the data with quotes
        local formatted_data="\"$time\",\"$balance\""
        echo "$formatted_data" >> "$filename"
    else
        echo "❌ Error: Failed to retrieve balance."
        exit 1
    fi
}

# Main function
main() {
    local current_time
    current_time=$(date +'%d/%m/%Y %H:%M')
    
    local balance
    balance=$(get_unclaimed_balance)
    
    if [ "$balance" != "ERROR" ]; then
        local data_to_write="$current_time,$balance"
        write_to_csv "$data_to_write"
    else
        echo "❌ Error: Failed to retrieve balance."
        exit 1
    fi
}

# Run main function
main