#!/bin/bash

# CPU limit checks snippet - to be added to node update script

#===========================
# Set variables
#===========================
# Set service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
# User working folder
HOME=$(eval echo ~$USER)
# Node path
NODE_PATH="$HOME/ceremonyclient/node"

#===========================
# Check if ceremonyclient directory exists
#===========================
HOME=$(eval echo ~$USER)
CEREMONYCLIENT_DIR="$HOME/ceremonyclient"

if [ ! -d "$CEREMONYCLIENT_DIR" ]; then
    echo "❌ Error: You don't have a node installed yet. Nothing to update. Exiting..."
    exit 1
fi

#===========================
# CPU limit cheks
#===========================
# Calculate the number of vCores
vCORES=$(nproc)

# Check if CPUQuota exists
if grep -q "CPUQuota=" "$SERVICE_FILE"; then
    # Extract the current CPU limit percentage
    CURRENT_CPU_LIMIT=$(grep -oP '(?<=CPUQuota=)\d+' "$SERVICE_FILE")
    
    # Calculate the current CPUQuota value
    CURRENT_CPU_QUOTA=$(( $CURRENT_CPU_LIMIT / $vCORES ))
    
    # Ask the user if they want to change the current CPU limit
    read -p "Your CPU is already limited to $CURRENT_CPU_QUOTA%. Do you want to change this? (Y/N): " CHANGE_CPU_LIMIT
    
    if [[ "$CHANGE_CPU_LIMIT" =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter the new CPU limit percentage (0-100) - enter 0 for no limit: " CPU_LIMIT_PERCENT
            
            # Validate the input
            if [[ "$CPU_LIMIT_PERCENT" =~ ^[0-9]+$ ]] && [ "$CPU_LIMIT_PERCENT" -ge 0 ] && [ "$CPU_LIMIT_PERCENT" -le 100 ]; then
                break  # Break out of the loop if the input is valid
            else
                echo "❌ Invalid input. Please enter a number between 0 and 100."
            fi
        done

        if [ "$CPU_LIMIT_PERCENT" -eq 0 ]; then
            echo "⚠️ No CPUQuota will be set."
        else
            echo "✅ CPU limit percentage set to: $CPU_LIMIT_PERCENT%"
            sleep 1

            # Calculate the new CPUQuota value
            CPU_QUOTA=$(( ($CPU_LIMIT_PERCENT * $vCORES) / 100 ))
            echo "☑️ Your CPUQuota value will be $CPU_LIMIT_PERCENT% of $vCORES vCores = $CPU_QUOTA%"
            sleep 1

            # Add CPUQuota to the service file
            echo "➕ Adding CPUQuota to ceremonyclient service file..."
            if ! sudo sed -i "/\[Service\]/a CPUQuota=${CPU_QUOTA}%" "$SERVICE_FILE"; then
                echo "❌ Error: Failed to add CPUQuota to ceremonyclient service file." >&2
                exit 1
            else
                echo "✅ A CPU limit of $CPU_LIMIT_PERCENT% has been applied"
                echo "You can change this manually later in your service file if you need"
            fi
            sleep 1  # Add a 1-second delay
        fi
    elif [[ "$CHANGE_CPU_LIMIT" =~ ^[Nn]$ ]]; then
        echo "🔄 CPUQuota will not be changed. Moving on..."
    else
        echo "❌ Invalid input. CPUQuota will not be changed. Moving on..."
    fi
else
    # CPUQuota does not exist, proceed with setting a new CPU limit
    while true; do
        read -p "Enter the CPU limit percentage (0-100) - enter 0 for no limit: " CPU_LIMIT_PERCENT

        # Validate the input
        if [[ "$CPU_LIMIT_PERCENT" =~ ^[0-9]+$ ]] && [ "$CPU_LIMIT_PERCENT" -ge 0 ] && [ "$CPU_LIMIT_PERCENT" -le 100 ]; then
            break  # Break out of the loop if the input is valid
        else
            echo "❌ Invalid input. Please enter a number between 0 and 100."
        fi
    done

    if [ "$CPU_LIMIT_PERCENT" -eq 0 ]; then
        echo "⚠️ No CPUQuota will be set."
    else
        echo "✅ CPU limit percentage set to: $CPU_LIMIT_PERCENT%"
        sleep 1

        # Calculate the CPUQuota value
        CPU_QUOTA=$(( $CPU_LIMIT_PERCENT * $vCORES ))
        echo "☑️ Your CPUQuota value will be $CPU_LIMIT_PERCENT% of $vCORES vCores = $CPU_QUOTA%"
        sleep 1

        # Add CPUQuota to the service file
        echo "➕ Adding CPUQuota to ceremonyclient service file..."
        if ! sudo sed -i "/\[Service\]/a CPUQuota=${CPU_QUOTA}%" "$SERVICE_FILE"; then
            echo "❌ Error: Failed to add CPUQuota to ceremonyclient service file." >&2
            exit 1
        else
            echo "✅ A CPU limit of $CPU_LIMIT_PERCENT% has been applied"
            echo "You can change this manually later in your service file if you need"
        fi
        sleep 1  # Add a 1-second delay
    fi
fi



