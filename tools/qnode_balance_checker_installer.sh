#!/bin/bash

set -e

echo "This installer will install a script to check your node balance"
echo "and then set up cronjob to log your balance every hour."
echo
echo "If your node version is not 1.4.19 and you system architecture is not 'amd64'"
echo "you will need to chnage manually this variable at the beginning of this script:"
echo "'~/scripts/balance_checker.sh'"
sleep 3

echo "Installing Python 3 and pip3..."
sudo apt install -y python3 python3-pip || { echo "❌ Failed to install Python 3 and pip3."; exit 1; }
sleep 1

echo "Removing existing script if it exists..."
rm -f ~/scripts/qnode_balance_checker.py

echo "Creating directory for scripts..."
mkdir -p ~/scripts

echo "Downloading new script..."
wget -q -P ~/scripts -O ~/scripts/qnode_balance_checker.sh https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_balance_checker.sh

echo "Setting executable permissions for the script..."
chmod +x ~/scripts/qnode_balance_checker.sh

echo "Checking if a cronjob exists for qnode_balance_checker.py and deleting it if found..."
crontab -l | grep -v "qnode_balance_checker.sh" | crontab -

echo "Setting up cronjob to run the script once every hour..."
(crontab -l ; echo "0 * * * * ~/scripts/qnode_balance_checker.sh") | crontab -

echo "Installer script completed!"
echo "Cronjob set!"
echo
echo "The script will now log your node balance every hour in ~/scripts/balance_log.csv"
echo "To see the log just run 'cat ~/scripts/balance_log.csv'"
