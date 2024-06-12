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

# Remove existing qone.sh if it exists
if [ -e ~/qone.sh ]; then
    rm ~/qone.sh
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to remove qone.sh"
    fi
fi

# Download the qone.sh script
wget -O ~/qone.sh https://github.com/lamat1111/QuilibriumScripts/raw/testing/qone.sh
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

# Check if the qone.sh setup section is already present in .bashrc
if grep -Fxq "# === qone.sh setup ===" ~/.bashrc; then
    echo "⚠️ The qone.sh setup section is already present in .bashrc."
    echo "Skipping the setup steps..."
else
    # Check if there's already a section for another script in .bashrc
    if grep -q "# === [^=]*setup ===" ~/.bashrc; then
        echo "⚠️ Warning: Another script seems to be already set up to run on login."
        echo "To avoid conflicts, qone.sh will not be executed on login, but aliases will be set up."
        sleep 1
        # Define the section to add in .bashrc without the execution line
        bashrc_section=$(cat << 'EOF'
        
# === qone.sh setup ===
# The following lines are added to create aliases for qone.sh
alias qone='~/qone.sh'
alias q1='~/qone.sh'
alias Q1='~/qone.sh'
# === end qone.sh setup ===
EOF
)
    else
        # Define the section to add in .bashrc with the execution line
        bashrc_section=$(cat << 'EOF'
        
# === qone.sh setup ===
# The following lines are added to run qone.sh on login and create aliases for qone.sh
~/qone.sh #this runs .qone on login
alias qone='~/qone.sh'
alias q1='~/qone.sh'
alias Q1='~/qone.sh'
# === end qone.sh setup ===
EOF
)
    fi

    # Add the section to the end of .bashrc if not already present
    echo "$bashrc_section" >> ~/.bashrc
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to add section to .bashrc. No worries, this is optional."
        sleep 1
        # Continue execution even if adding section to .bashrc fails
    fi
fi

echo "To launch the Quickstart Node Menu run './qone.sh'"
