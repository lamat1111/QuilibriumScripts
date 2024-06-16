#!/bin/bash

# Set timezone to Europe/Rome
export TZ="Europe/Rome"

# Script version
SCRIPT_VERSION="1.5.5"

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

# Function to fetch node binary and set NODE_BINARY variable
fetch_node_binary() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        release_os="linux"
        release_arch=$(uname -m)
        if [[ "$release_arch" == "aarch64" ]]; then
            release_arch="arm64"
        else
            release_arch="amd64"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        release_os="darwin"
        release_arch="arm64"
    else
        echo "Unsupported OS for releases, please build from source"
        exit 1
    fi

    files=$(curl -s https://releases.quilibrium.com/release | grep "$release_os-$release_arch")

    for file in $files; do
        version=$(echo "$file" | cut -d '-' -f 2)
        break
    done

    NODE_BINARY=node-$version-$release_os-$release_arch
    echo "$NODE_BINARY"
}

# Function to get the unclaimed balance
get_unclaimed_balance() {
    local node_directory="$HOME/ceremonyclient/node"
    local NODE_BINARY
    NODE_BINARY=$(fetch_node_binary)
    local node_command="./$NODE_BINARY -balance"
    
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    
    local balance
    balance=$(echo "$output" | grep "Unclaimed balance" | awk '{print $3}' | sed 's/[^0-9.]//g')
    
    if [[ "$balance" =~ ^[0-9.]+$ ]]; then
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

    if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
        echo "time,balance" > "$filename"
    fi

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
        
        local data_to_write="$current_time,$balance"
        
        write_to_csv "$data_to_write"
    fi
}

# Run main function
main
