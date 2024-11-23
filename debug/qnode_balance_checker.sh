#!/bin/bash

# Set timezone to Europe/Rome
export TZ="Europe/Rome"
echo "🔧 DEBUG: Timezone set to $TZ"

# Script version
SCRIPT_VERSION="1.5.8"
echo "📌 DEBUG: Script version: $SCRIPT_VERSION"

# Function to check for newer script version
check_for_updates() {
    echo "🔄 DEBUG: Checking for script updates..."
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    echo "📊 DEBUG: Latest version available: $LATEST_VERSION"
    echo "📊 DEBUG: Current version: $SCRIPT_VERSION"
    
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        echo "⚡ DEBUG: New version found! Updating script..."
        wget -O ~/scripts/qnode_balance_checker.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_checker.sh"
        chmod +x ~/scripts/qnode_balance_checker.sh
        echo "✅ DEBUG: Script updated successfully"
        sleep 1
    else
        echo "✅ DEBUG: Script is up to date"
    fi
}

# Check for updates and update if available
echo "🔍 DEBUG: Starting update check process..."
#check_for_updates

# Function to get the node binary name
get_node_binary() {
    echo "🔍 DEBUG: Looking for node binary..."
    local node_dir="$HOME/ceremonyclient/node"
    echo "📂 DEBUG: Searching in directory: $node_dir"
    
    local binary_name
    binary_name=$(find "$node_dir" -name "node-[0-9]*" ! -name "*.dgst*" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1 | xargs basename)
    
    if [ -z "$binary_name" ]; then
        echo "❌ DEBUG: No executable node binary found in $node_dir"
        return 1
    fi
    
    echo "✅ DEBUG: Found binary: $binary_name"
    echo "$binary_name"
}

# Function to get the unclaimed balance
get_unclaimed_balance() {
    echo "💰 DEBUG: Getting unclaimed balance..."
    local node_directory="$HOME/ceremonyclient/node"
    echo "📂 DEBUG: Node directory: $node_directory"
    
    local NODE_BINARY
    NODE_BINARY=$(get_node_binary)
    echo "🔧 DEBUG: Using binary: $NODE_BINARY"
    
    if [ "$NODE_BINARY" == "ERROR:"* ]; then
        echo "❌ DEBUG: Failed to get node binary"
        echo "ERROR"
        return 1
    fi
    
    local node_command="./$NODE_BINARY -balance"
    echo "🔧 DEBUG: Executing command: $node_command"
    
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    echo "📝 DEBUG: Raw output: $output"
    
    local balance
    balance=$(echo "$output" | grep "Owned balance" | awk '{print $3}' | sed 's/QUIL//g' | tr -d ' ')
    echo "💵 DEBUG: Extracted balance: $balance"
    
    if [[ "$balance" =~ ^[0-9.]+$ ]]; then
        echo "✅ DEBUG: Valid balance found"
        echo "$balance"
    else
        echo "❌ DEBUG: Invalid balance format"
        echo "ERROR"
    fi
}

# Function to write data to CSV file
write_to_csv() {
    echo "📝 DEBUG: Starting CSV write process..."
    local filename="$HOME/scripts/balance_log.csv"
    local data="$1"
    
    echo "📂 DEBUG: CSV file path: $filename"
    echo "📊 DEBUG: Data to write: $data"
    
    if [ ! -f "$filename" ] || [ ! -s "$filename" ]; then
        echo "📝 DEBUG: Creating new CSV file with headers"
        echo "time,balance" > "$filename"
    else
        echo "✅ DEBUG: CSV file exists"
    fi
    
    # Split the data into time and balance
    local time=$(echo "$data" | cut -d',' -f1)
    local balance=$(echo "$data" | cut -d',' -f2)
    echo "⏰ DEBUG: Time: $time"
    echo "💰 DEBUG: Balance: $balance"
    
    # Only process if balance is not an error
    if [ "$balance" != "ERROR" ]; then
        # Round to 2 decimal places and replace dot with comma
        balance=$(printf "%.2f" "$balance" | sed 's/\./,/')
        echo "💵 DEBUG: Formatted balance: $balance"
        
        # Format the data with quotes
        local formatted_data="\"$time\",\"$balance\""
        echo "📊 DEBUG: Formatted data: $formatted_data"
        echo "$formatted_data" >> "$filename"
        echo "✅ DEBUG: Data written to CSV successfully"
    else
        echo "❌ DEBUG: Error: Failed to retrieve balance."
        exit 1
    fi
}

# Main function
main() {
    echo "🚀 DEBUG: Starting main function..."
    
    local current_time
    current_time=$(date +'%d/%m/%Y %H:%M')
    echo "⏰ DEBUG: Current time: $current_time"
    
    local balance
    echo "💰 DEBUG: Getting balance..."
    balance=$(get_unclaimed_balance)
    echo "💵 DEBUG: Retrieved balance: $balance"
    
    if [ "$balance" != "ERROR" ]; then
        local data_to_write="$current_time,$balance"
        echo "📊 DEBUG: Preparing to write data: $data_to_write"
        write_to_csv "$data_to_write"
        echo "✅ DEBUG: Main function completed successfully"
    else
        echo "❌ DEBUG: Error: Failed to retrieve balance."
        exit 1
    fi
}

# Run main function
echo "🎬 DEBUG: Starting script execution..."
main
echo "🏁 DEBUG: Script execution completed"