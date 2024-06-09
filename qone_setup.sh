#!/bin/bash

# Check if wget is installed, and install it if necessary
if ! command -v wget &> /dev/null; then
    echo "⌛️ wget is not installed. Installing wget..."
    sleep 1
    sudo apt update
    sudo apt install wget -y
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to install wget."
        exit 1
    fi
fi

# Download the qone.sh script
wget -O ~/qone.sh https://github.com/lamat1111/QuilibriumScripts/raw/main/qone.sh
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to download qone.sh script."
    exit 1
fi

# Make qone.sh executable
chmod +x ~/qone.sh
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to make qone.sh executable. You will have to do this manually."
    sleep 1
    # Continue execution even if chmod fails
fi

# Define the section to add in .bashrc
bashrc_section=$(cat << 'EOF'

# === qone.sh setup ===
# The following lines are added to run qone.sh on login and create aliases for qone.sh
~/qone.sh
alias qone='~/qone.sh'
alias q1='~/qone.sh'
alias Q1='~/qone.sh'
# === end qone.sh setup ===
EOF
)

# Add the section to the end of .bashrc if not already present
if ! grep -Fxq "# === qone.sh setup ===" ~/.bashrc; then
    echo "$bashrc_section" >> ~/.bashrc
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to add section to .bashrc. No worries, this is optional."
        sleep 1
        # Continue execution even if adding section to .bashrc fails
    fi
fi

# Reload .bashrc to apply changes
source ~/.bashrc
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to reload .bashrc. No worries, this is optional."
    sleep 1
    # Continue execution even if reloading .bashrc fails
fi

echo "✅ Setup complete!"
echo "You can now use 'qone', 'q1', or 'Q1' to launch the Node Quickstart Menu"
echo "The menu will also load automatically every time you log in."
echo ""
echo "⌛️ Opening the menu..."
sleep 3

# Execute qone.sh
~/qone.sh
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to execute qone.sh. Try to run './qone.sh' manually"
fi
