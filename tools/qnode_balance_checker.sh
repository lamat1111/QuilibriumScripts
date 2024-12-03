#!/bin/bash

SCRIPT_VERSION="1.6.3"

###################
# Constants
###################

readonly NODE_DIR="$HOME/ceremonyclient/node"
readonly SCRIPTS_DIR="$HOME/scripts"
readonly BALANCE_LOG="$SCRIPTS_DIR/balance_log.csv"
readonly MIGRATION_FLAG="$SCRIPTS_DIR/balance_log_fix_applied"

###################
# Utility Functions
###################

check_for_updates() {
    LATEST_VERSION=$(curl -s "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        curl -s -o "$SCRIPTS_DIR/qnode_balance_checker.sh" "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker.sh"
        chmod +x "$SCRIPTS_DIR/qnode_balance_checker.sh"
        sleep 1
    fi
}

check_and_migrate() {
    local temp_file="$BALANCE_LOG.tmp"
    
    # Skip if already migrated
    [ -f "$MIGRATION_FLAG" ] && { rm "$MIGRATION_FLAG"; return 0; }

    # Check file existence and readability
    if [ ! -f "$BALANCE_LOG" ] || [ ! -r "$BALANCE_LOG" ]; then
        echo
        echo "❌ Error: Migration failed - File not found or not readable"
        echo "This is ok if you are installing the sript for the first time"
        echo
        return 1
    fi
    
    head -n 1 "$BALANCE_LOG" > "$temp_file"
    
    tail -n +2 "$BALANCE_LOG" | while IFS= read -r line; do
        local balance=$(echo "$line" | sed 's/^[^,]*,"\(.*\)"$/\1/')
        local time=$(echo "$line" | sed 's/^"\(.*\)",.*$/\1/')
        
        # Convert balance format (comma to dot)
        balance=$(echo "$balance" | sed 's/,/\./')
        
        # Only convert date if it matches DD/MM/YYYY format
        if echo "$time" | grep -q '^[0-9]\{1,2\}/[0-9]\{1,2\}/[0-9]\{4\}'; then
            time=$(echo "$time" | sed 's/\([0-9]*\)\/\([0-9]*\)\/\([0-9]*\) \(.*\)/\3-\2-\1 \4/')
        fi
        
        echo "\"$time\",\"$balance\"" >> "$temp_file"
    done
    
    if [ -s "$temp_file" ]; then
        cp "$BALANCE_LOG" "$BALANCE_LOG.backup"
        mv "$temp_file" "$BALANCE_LOG"
        touch "$MIGRATION_FLAG"
        echo "✅ Done"
    else
        rm "$temp_file"
        echo "❌ Error: Migration failed - Processing error"
        return 1
    fi
}

###################
# Core Functions
###################

get_node_binary() {
    local binary_name
    binary_name=$(find "$NODE_DIR" -name "node-[0-9]*" ! -name "*.dgst*" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1 | xargs basename)
    
    if [ -z "$binary_name" ]; then
        echo "ERROR: No executable node binary found in $NODE_DIR"
        return 1
    fi
    
    echo "$binary_name"
}

get_unclaimed_balance() {
    local NODE_BINARY
    NODE_BINARY=$(get_node_binary)
    
    if [ "$NODE_BINARY" == "ERROR:"* ]; then
        echo "ERROR"
        return 1
    fi
    
    local node_command="./$NODE_BINARY -balance"
    local output
    output=$(cd "$NODE_DIR" && $node_command 2>&1)
    
    local balance
    balance=$(echo "$output" | grep "Owned balance" | awk '{print $3}' | sed 's/QUIL//g' | tr -d ' ')
    
    if [[ "$balance" =~ ^[0-9.]+$ ]]; then
        echo "$balance"
    else
        echo "ERROR"
    fi
}

write_to_csv() {
    local data="$1"
    
    if [ ! -f "$BALANCE_LOG" ] || [ ! -s "$BALANCE_LOG" ]; then
        echo "time,balance" > "$BALANCE_LOG"
    fi
    
    local time=$(echo "$data" | cut -d',' -f1)
    local balance=$(echo "$data" | cut -d',' -f2)
    
    if [ "$balance" != "ERROR" ]; then
        balance=$(echo "$balance" | tr ',' '.' | sed 's/[[:space:]]//g')
        
        if ! echo "$balance" | grep -E '^[0-9]+\.?[0-9]*$' > /dev/null; then
            echo "❌ Error: Invalid number format: $balance"
            return 1
        fi
        
        local formatted_data="\"$time\",\"$balance\""
        echo "$formatted_data" >> "$BALANCE_LOG"
        return 0
    else
        echo "❌ Error: Failed to retrieve balance."
        return 1
    fi
}

###################
# Main Function
###################

main() {
    # Initialize
    check_and_migrate
    check_for_updates
    
    # Get current balance
    local current_time
    current_time=$(date +'%Y-%m-%d %H:%M')
    
    local balance
    balance=$(get_unclaimed_balance)
    
    # Write balance to log
    if [ "$balance" != "ERROR" ]; then
        local data_to_write="$current_time,$balance"
        if ! write_to_csv "$data_to_write"; then
            exit 1
        fi
    else
        echo "❌ Error: Failed to retrieve balance."
        exit 1
    fi
}

main