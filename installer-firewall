#!/bin/bash

# Function to check if a UFW rule exists
ufw_rule_exists() {
    sudo ufw status numbered | grep -qF "$1"
}

# Step 3: Configure Firewall
echo "Configuring firewall..."
echo "y" | sudo ufw enable || { echo "Failed to enable firewall! Exiting..."; exit 1; }

for port in 22 8336 443; do
    if ! ufw_rule_exists "${port}"; then
        sudo ufw allow "${port}" || { echo "Error: Failed to allow port ${port}!" >&2; exit 1; }
    fi
done

sudo ufw status

# Message at the end
echo "Firewall setup was successful."
