#!/bin/bash

# CONFIG FILE UPDATE for "REWARDS TO GOOGLE SHEET SCRIPT"

QNODE_DIR="$HOME/ceremonyclient/node"

# Get current node binary name (just the executable, excluding .dgst and .sig files)
QNODE_BINARY_NAME=$(find "$QNODE_DIR" -name "node-[0-9]*" ! -name "*.dgst*" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1 | xargs basename)

if [ -n "$QNODE_BINARY_NAME" ]; then
    echo "Found local node binary: $QNODE_BINARY_NAME"
else
    echo "❌ No local node binary found in $QNODE_DIR"
    exit 1
fi

# Define the config files
CONFIG_FILE1="$HOME/scripts/qnode_rewards_to_gsheet.config"
CONFIG_FILE2="$HOME/scripts/qnode_rewards_to_gsheet_2.config"

# Function to display section headers
display_header() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
    echo
}

# Check if either of the config files exist
if [ -f "$CONFIG_FILE1" ] || [ -f "$CONFIG_FILE2" ]; then
    display_header "UPDATING EXTRA CONFIG FILES (OPTIONAL)"

    echo "This is an optional section that almost nobody needs."
    echo "Don't worry if you receive errors."
    echo

    # Function to update config file
    update_config_file() {
        local config_file="$1"
        
        echo "✅ Checking node version in config file '$(basename "$config_file")'."
        
        # Get the current NODE_BINARY from the config file
        config_node_binary=$(grep -E "^NODE_BINARY\s*=\s*" "$config_file" | sed -E 's/^NODE_BINARY\s*=\s*//' | tr -d '"' | tr -d "'")
        
        if [ -z "$config_node_binary" ]; then
            echo "❌ Could not find NODE_BINARY in config file"
            return
        fi

        echo "Config file currently has: $config_node_binary"
        
        # Compare binary names
        if [ "$config_node_binary" = "$QNODE_BINARY_NAME" ]; then
            echo "✅ Node binary names match. No update needed."
        else
            echo "⏳ Node binary names differ. Updating config file..."
            echo "Current value: $config_node_binary"
            echo "New value: $QNODE_BINARY_NAME"
            
            # Create a backup of the config file
            cp "$config_file" "${config_file}.backup"
            
            # Update the config file preserving the original spacing format
            if grep -q "^NODE_BINARY\s*=\s*" "$config_file"; then
                # Format with spaces exists, preserve it
                original_format=$(grep -E "^NODE_BINARY\s*=\s*" "$config_file" | sed -E 's/NODE_BINARY(\s*=\s*).*/\1/')
                sed -E "s|^NODE_BINARY\s*=\s*.*|NODE_BINARY${original_format}${QNODE_BINARY_NAME}|" "$config_file" > "${config_file}.tmp"
            else
                # No spaces format
                sed "s|^NODE_BINARY=.*|NODE_BINARY=${QNODE_BINARY_NAME}|" "$config_file" > "${config_file}.tmp"
            fi
            
            if [ -s "${config_file}.tmp" ]; then
                mv "${config_file}.tmp" "$config_file"
                echo "✅ Config file updated successfully."
            else
                echo "❌ Failed to update config file (empty temp file). Restoring backup..."
                mv "${config_file}.backup" "$config_file"
            fi
        fi
    }

    # Array of config files
    config_files=("$CONFIG_FILE1" "$CONFIG_FILE2")

    # Loop through config files
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            update_config_file "$config_file"
            echo "-------------------"
        else
            echo "Config file not found: $config_file"
        fi
    done

    echo "All config files processed."
fi