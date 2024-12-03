#!/bin/bash

check_and_migrate() {
    echo "Migrating date and time to new format in balance log..."
    local flag_file="$HOME/scripts/balance_log_fix_applied"
    
    # Skip if already migrated
    [ -f "$flag_file" ] && { rm "$flag_file"; }

    local filename="$HOME/scripts/balance_log.csv"
    local temp_file="$filename.tmp"
    
    [ ! -f "$filename" ] && { echo "❌ Error: Migration failed"; exit 1; }
    [ ! -r "$filename" ] && { echo "❌ Error: Migration failed"; exit 1; }
    
    head -n 1 "$filename" > "$temp_file"
    
    tail -n +2 "$filename" | while IFS= read -r line; do
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
        cp "$filename" "$filename.backup"
        mv "$temp_file" "$filename"
        touch "$flag_file"
        echo "✅ Done!"
    else
        rm "$temp_file"
        echo "❌ Error: Migration failed."
        exit 1
    fi
}

check_and_migrate