#!/bin/bash

# Script version
SCRIPT_VERSION="1.3"

# Define the node binary filename
#NODE_BINARY="node-1.4.19-linux-amd64"

# Function to check for newer script version
check_for_updates() {
    echo "⚙️ Checking for script updates..."
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/scripts/qnode_balance_checker.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh"
        chmod +x ~/scripts/qnode_balance_checker.sh
        echo "✅ New version downloaded: V $SCRIPT_VERSION."
	sleep 1
    fi
}

# Check for updates and update if available
check_for_updates

# Set the version number
VERSION=$(cat $HOME/ceremonyclient/node/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Get the system architecture
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    NODE_BINARY="node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    NODE_BINARY="node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    NODE_BINARY="node-$VERSION-darwin-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

cat << "EOF"

                  QQQQQQQQQ       1111111   
                QQ:::::::::QQ    1::::::1   
              QQ:::::::::::::QQ 1:::::::1   
             Q:::::::QQQ:::::::Q111:::::1   
             Q::::::O   Q::::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O  QQQQ:::::Q   1::::l   
             Q::::::O Q::::::::Q   1::::l   
             Q:::::::QQ::::::::Q111::::::111
              QQ::::::::::::::Q 1::::::::::1
                QQ:::::::::::Q  1::::::::::1
                  QQQQQQQQ::::QQ111111111111
                          Q:::::Q           
                           QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


===================================================================
               ✨ NODE BALANCE LOGGER SCRIPT ✨
===================================================================
This script check your node balance and logs it to a CSV file.
It also calculate the increase of your balance for every hour.

Made with 🔥 by LaMat - https://quilibrium.one
===================================================================

EOF
echo "Version: $SCRIPT_VERSION"
echo
echo "Processing... ⏳"

sleep 3

## Function to get the unclaimed balance
get_unclaimed_balance() {
    echo
    echo "⚙️ Retrieving unclaimed balance..."
    local node_directory="$HOME/ceremonyclient/node"
    local NODE_BINARY
    NODE_BINARY=$(get_node_binary_filename)
    local node_command="./$NODE_BINARY -balance"
    
    # Run node command and capture output
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    
    # Parse output to find unclaimed balance
    local balance
    balance=$(echo "$output" | grep "Unclaimed balance" | awk '{print $3}')
    
    # Check if balance is a valid number
    if [[ "$balance" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
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

    echo
    echo "⚙️ Writing data to CSV file..."

    # Check if file exists to determine if headers need to be written
    if [ ! -f "$filename" ]; then
        echo "time,balance,increase" > "$filename"
    fi

    # Append data to CSV
    echo "$data" >> "$filename"
    sleep 1
}

# Main function
main() {
    local current_time
    current_time=$(date +'%d/%m/%Y %H:%M')
    
    local balance
    balance=$(get_unclaimed_balance)
    
    if [ -n "$balance" ]; then
        local previous_balance="$balance"  # For now, assume it's the same balance

        # Calculate increase in balance over one hour
        local increase
        increase=$(echo "$balance - $previous_balance" | bc)

        # Format increase and balance to required precision
        local formatted_balance
        formatted_balance=$(printf "%.2f" "$balance")
        
        local formatted_increase
        formatted_increase=$(printf "%.5f" "$increase")
        
        # Print data
        local data_to_write="$current_time,$formatted_balance,$formatted_increase"
        echo "$data_to_write"
        
        # Write to CSV file
        write_to_csv "$data_to_write"
    fi
}

# Run main function
main