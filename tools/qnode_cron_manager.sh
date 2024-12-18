#!/bin/bash

# Function to display usage
show_usage() {
    echo "Usage: $0 [MODE]"
    echo "Available modes:"
    echo "  0 - Run normally with interactive prompts"
    echo "  1 - Deactivate all monitoring cronjobs"
    echo "  2 - Activate all monitoring cronjobs"
    echo "  3 - Deactivate qnode_rewards_to_gsheet_2.py only"
    echo "  4 - Deactivate qnode_rewards_to_gsheet.py only"
    echo "  5 - Activate qnode_rewards_to_gsheet_2.py only"
    echo "  6 - Activate qnode_rewards_to_gsheet.py only"
    echo "Example: $0 1"
}

# Set execution mode from command line argument or default to 0
EXECUTION_MODE=${1:-0}

# Function to display current crontab
show_crontab() {
    echo "Current crontab:"
    echo "================================"
    crontab -l
    echo "================================"
}

# Function to modify specific crontab entry
modify_specific_crontab() {
    local script_name=$1
    local action=$2
    local temp_file=$(mktemp)
    
    crontab -l > "$temp_file"
    
    if [ "$action" = "deactivate" ]; then
        # Use word boundaries to ensure exact match
        sed -i "\|\b${script_name}\b|{/^#/!s/^/#/}" "$temp_file"
        echo "Deactivated cronjob for ${script_name}"
    elif [ "$action" = "activate" ]; then
        # Use word boundaries to ensure exact match
        sed -i "\|\b${script_name}\b|s/^#*//" "$temp_file"
        echo "Activated cronjob for ${script_name}"
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
        # More precise matching for each script
        sed -i '\|\bqnode_rewards_to_gsheet_2\.py\b|{/^#/!s/^/#/}' "$temp_file"
        sed -i '\|\bqnode_rewards_to_gsheet\.py\b|{/^#/!s/^/#/}' "$temp_file"
        sed -i '\|\bqnode_balance_checker\.sh\b|{/^#/!s/^/#/}' "$temp_file"
        echo "Deactivated all node balance monitoring cronjobs."
    elif [ "$action" = "activate" ]; then
        sed -i '\|\bqnode_rewards_to_gsheet_2\.py\b|s/^#*//' "$temp_file"
        sed -i '\|\bqnode_rewards_to_gsheet\.py\b|s/^#*//' "$temp_file"
        sed -i '\|\bqnode_balance_checker\.sh\b|s/^#*//' "$temp_file"
        echo "Activated all node balance monitoring cronjobs."
    fi
    
    crontab "$temp_file"
    rm "$temp_file"
}

# Validate execution mode
if ! [[ "$EXECUTION_MODE" =~ ^[0-6]$ ]]; then
    echo "Error: Invalid execution mode '$EXECUTION_MODE'"
    show_usage
    exit 1
fi

# Main execution logic
case $EXECUTION_MODE in
    0)
        # Run single command with prompts
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
                modify_specific_crontab "qnode_rewards_to_gsheet_2.py" "deactivate"
                ;;
            4)
                modify_specific_crontab "qnode_rewards_to_gsheet.py" "deactivate"
                ;;
            5)
                modify_specific_crontab "qnode_rewards_to_gsheet_2.py" "activate"
                ;;
            6)
                modify_specific_crontab "qnode_rewards_to_gsheet.py" "activate"
                ;;
            7)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                exit 1
                ;;
        esac
        
        show_crontab
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
        modify_specific_crontab "qnode_rewards_to_gsheet_2.py" "deactivate"
        show_crontab
        ;;
    4)
        modify_specific_crontab "qnode_rewards_to_gsheet.py" "deactivate"
        show_crontab
        ;;
    5)
        modify_specific_crontab "qnode_rewards_to_gsheet_2.py" "activate"
        show_crontab
        ;;
    6)
        modify_specific_crontab "qnode_rewards_to_gsheet.py" "activate"
        show_crontab
        ;;
esac