#!/bin/bash

# Function to display current crontab
show_crontab() {
    echo
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
        sed -i '/qnode_rewards_to_gsheet\.sh$/ s/^/#/' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet_2\.sh$/ s/^/#/' "$temp_file"
        sed -i '/qnode_balance_checker$/ s/^/#/' "$temp_file"
    elif [ "$action" = "activate" ]; then
        sed -i '/qnode_rewards_to_gsheet\.sh$/ s/^#//' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet_2\.sh$/ s/^#//' "$temp_file"
        sed -i '/qnode_balance_checker$/ s/^#//' "$temp_file"
    fi
    
    crontab "$temp_file"
    rm "$temp_file"
}

# Main menu
while true; do
    echo "Choose an option:"
    echo "1) Deactivate all cronjobs that query the node balance"
    echo "2) Activate all cronjobs that query the node balance"
    echo "3) Exit"
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            modify_crontab "deactivate"
            echo "Deactivated cronjobs that query the node balance."
            show_crontab
            ;;
        2)
            modify_crontab "activate"
            echo "Activated cronjobs that query the node balance."
            show_crontab
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