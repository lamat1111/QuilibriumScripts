#!/bin/bash

# Set the execution mode here:
# 0 - Run normally with prompts
# 1 - Run option 1 (deactivate) directly
# 2 - Run option 2 (activate) directly
EXECUTION_MODE=1

# Function to display current crontab
show_crontab() {
    echo "Current crontab:"
    echo "================================"
    crontab -l
    echo "================================"
}

# Function to modify crontab
modify_crontab() {
    local action=$1
    local temp_file=$(mktemp)
    
    crontab -l > "$temp_file"
    
    if [ "$action" = "deactivate" ]; then
        sed -i '/qnode_rewards_to_gsheet_2\.py/ s/^/#/' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet\.py/ s/^/#/' "$temp_file"
        sed -i '/qnode_balance_checker\.sh/ s/^/#/' "$temp_file"
        echo "Deactivated cronjobs that query the node balance."
    elif [ "$action" = "activate" ]; then
        sed -i '/qnode_rewards_to_gsheet_2\.py/ s/^#//' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet\.py/ s/^#//' "$temp_file"
        sed -i '/qnode_balance_checker\.sh/ s/^#//' "$temp_file"
        echo "Activated cronjobs that query the node balance."
    fi
    
    crontab "$temp_file"
    rm "$temp_file"
    
    show_crontab
}

# Main execution logic
case $EXECUTION_MODE in
    0)
        # Run normally with prompts
        while true; do
            echo "Choose an option:"
            echo "1) Deactivate all cronjobs that query the node balance"
            echo "2) Activate all cronjobs that query the node balance"
            echo "3) Exit"
            read -p "Enter your choice (1-3): " choice
            
            case $choice in
                1)
                    modify_crontab "deactivate"
                    ;;
                2)
                    modify_crontab "activate"
                    ;;
                3)
                    echo "Exiting..."
                    exit 0
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
            
            echo
        done
        ;;
    1)
        # Run option 1 (deactivate) directly
        modify_crontab "deactivate"
        ;;
    2)
        # Run option 2 (activate) directly
        modify_crontab "activate"
        ;;
    *)
        echo "Invalid EXECUTION_MODE. Please set it to 0, 1, or 2."
        exit 1
        ;;
esac