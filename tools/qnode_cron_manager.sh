#!/bin/bash

# Set the execution mode here:
# 0 - Run normally with prompts
# 1 - Run option 1 (deactivate all)
# 2 - Run option 2 (activate all)
# 3 - Run option 3 (deactivate qnode_rewards_to_gsheet_2.py only)
# 4 - Run option 4 (deactivate qnode_rewards_to_gsheet.py only)
# 5 - Run option 5 (activate qnode_rewards_to_gsheet_2.py only)
# 6 - Run option 6 (activate qnode_rewards_to_gsheet.py only)
EXECUTION_MODE=6

# Function to display current crontab
show_crontab() {
    echo "Current crontab:"
    echo "================================"
    crontab -l
    echo "================================"
}

# Function to modify specific crontab entry
modify_specific_crontab() {
    local pattern=$1
    local action=$2
    local temp_file=$(mktemp)
    
    crontab -l > "$temp_file"
    
    if [ "$action" = "deactivate" ]; then
        # Check if the line is not already commented and contains the pattern
        sed -i "/${pattern}/ s/^[^#]/&#/" "$temp_file"
        echo "Deactivated cronjob containing ${pattern}"
    elif [ "$action" = "activate" ]; then
        # Remove any number of leading # characters
        sed -i "/${pattern}/ s/^#\+//" "$temp_file"
        echo "Activated cronjob containing ${pattern}"
    fi
    
    crontab "$temp_file"
    rm "$temp_file"
}

# Function to modify all monitoring crontabs
modify_all_crontabs() {
    local action=$1
    local temp_file=$(mktemp)
    
    crontab -l > "$temp_file"
    
    if [ "$action" = "deactivate" ]; then
        # Check if the lines are not already commented
        sed -i '/qnode_rewards_to_gsheet_2\.py/ s/^[^#]/&#/' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet\.py/ s/^[^#]/&#/' "$temp_file"
        sed -i '/qnode_balance_checker\.sh/ s/^[^#]/&#/' "$temp_file"
        echo "Deactivated all node balance monitoring cronjobs."
    elif [ "$action" = "activate" ]; then
        # Remove any number of leading # characters
        sed -i '/qnode_rewards_to_gsheet_2\.py/ s/^#\+//' "$temp_file"
        sed -i '/qnode_rewards_to_gsheet\.py/ s/^#\+//' "$temp_file"
        sed -i '/qnode_balance_checker\.sh/ s/^#\+//' "$temp_file"
        echo "Activated all node balance monitoring cronjobs."
    fi
    
    crontab "$temp_file"
    rm "$temp_file"
}

# Main execution logic
case $EXECUTION_MODE in
    0)
        # Run normally with prompts
        while true; do
            echo "Choose an option:"
            echo "1) Deactivate all cronjobs that query the node balance"
            echo "2) Activate all cronjobs that query the node balance"
            echo "3) Deactivate qnode_rewards_to_gsheet_2.py only"
            echo "4) Deactivate qnode_rewards_to_gsheet.py only"
            echo "5) Activate qnode_rewards_to_gsheet_2.py only"
            echo "6) Activate qnode_rewards_to_gsheet.py only"
            echo "7) Exit"
            read -p "Enter your choice (1-7): " choice
            
            case $choice in
                1)
                    modify_all_crontabs "deactivate"
                    ;;
                2)
                    modify_all_crontabs "activate"
                    ;;
                3)
                    modify_specific_crontab "qnode_rewards_to_gsheet_2\.py" "deactivate"
                    ;;
                4)
                    modify_specific_crontab "qnode_rewards_to_gsheet\.py" "deactivate"
                    ;;
                5)
                    modify_specific_crontab "qnode_rewards_to_gsheet_2\.py" "activate"
                    ;;
                6)
                    modify_specific_crontab "qnode_rewards_to_gsheet\.py" "activate"
                    ;;
                7)
                    echo "Exiting..."
                    exit 0
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
            
            show_crontab
            echo
        done
        ;;
    1)
        modify_all_crontabs "deactivate"
        show_crontab
        ;;
    2)
        modify_all_crontabs "activate"
        show_crontab
        ;;
    3)
        modify_specific_crontab "qnode_rewards_to_gsheet_2\.py" "deactivate"
        show_crontab
        ;;
    4)
        modify_specific_crontab "qnode_rewards_to_gsheet\.py" "deactivate"
        show_crontab
        ;;
    5)
        modify_specific_crontab "qnode_rewards_to_gsheet_2\.py" "activate"
        show_crontab
        ;;
    6)
        modify_specific_crontab "qnode_rewards_to_gsheet\.py" "activate"
        show_crontab
        ;;
    *)
        echo "Invalid EXECUTION_MODE. Please set it to a value between 0 and 6."
        exit 1
        ;;
esac