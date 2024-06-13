#!/bin/bash

# Set timezone to Europe/Rome
export TZ="Europe/Rome"

# Script version
SCRIPT_VERSION="1.5.4"

# Function to check for newer script version
check_for_updates() {
    #echo "⚙️ Checking for script updates..."
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/scripts/qnode_balance_checker.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh"
        chmod +x ~/scripts/qnode_balance_checker.sh
        #echo "✅ New version downloaded: V $SCRIPT_VERSION."
        sleep 1
    fi
}

# Check for updates and update if available
check_for_updates

# Function to retrieve the node binary filename dynamically
get_node_binary_filename() {
    local version_file="$HOME/ceremonyclient/node/config/version.go"
    local version_hex=$(grep -A 1 "func GetVersion() \[\]byte {" "$version_file" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

    local arch=$(uname -m)
    local node_binary

    if [ "$arch" = "x86_64" ]; then
        node_binary="node-$version_hex-linux-amd64"
    elif [ "$arch" = "aarch64" ]; then
        node_binary="node-$version_hex-linux-arm64"
    elif [ "$arch" = "arm64" ]; then
        node_binary="node-$version_hex-darwin-arm64"
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi

    echo "$node_binary"
}

# Function to get the unclaimed balance
get_unclaimed_balance() {
    local node_directory="$HOME/ceremonyclient/node"
    local NODE_BINARY
    NODE_BINARY=$(get_node_binary_filename)
    local node_command="./$NODE_BINARY -balance"
    
    # Run node command and capture output
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    
    # Parse output to find unclaimed balance
    local balance
    balance=$(echo "$output" | grep "Unclaimed balance" | awk '{print $3}' | sed 's/[^0-9.]//g')
    
    # Check if balance is a valid number
    if [[ "$balance" =~ ^[0-9.]+$ ]]; then
        # Format balance to 2 decimal places
        balance=$(printf "%.2f" "$balance")
        echo "$balance"
    else
        echo "❌ Error: Failed to retrieve balance."
        exit 1
    fi
}

# Function to write data to CSV file
write_to_csv() {
    local filename="$HOME/scripts/balance_log.csv"
    local data="$1"

    # Check if file exists to determine if headers need to be written
    if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
        echo "time,balance,increase" > "$filename"
    fi

    # Append data to CSV
    echo "$data" >> "$filename"
}

# Main function
main() {
    local current_time
    current_time=$(date +'%d/%m/%Y %H:%M')
    
    local balance
    balance=$(get_unclaimed_balance)
    
    if [ -n "$balance" ]; then
        local filename="$HOME/scripts/balance_log.csv"
        
        # Read the last recorded balance and increase from CSV
        local last_record
        last_record=$(tail -n 1 "$filename" 2>/dev/null)
        local previous_balance=0
        local previous_increase=0
        
        if [ -n "$last_record" ]; then
            previous_balance=$(echo "$last_record" | awk -F ',' '{print $2}')
            previous_increase=$(echo "$last_record" | awk -F ',' '{print $3}')
        fi
        
        # Calculate increase in balance since last recorded balance
        local increase=$(echo "$balance - $previous_increase" | bc)
        
        # Format balance and increase to required precision
        local formatted_balance=$(printf "%.2f" "$balance")
        local formatted_increase=$(printf "%.5f" "$increase")
        
        # Print data
        local data_to_write="$current_time,$formatted_balance,$formatted_increase"
        
        # Write to CSV file
        if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
            echo "time,balance,increase" > "$filename"
        fi
        echo "$data_to_write" >> "$filename"
    fi
}

# Run main function
main
