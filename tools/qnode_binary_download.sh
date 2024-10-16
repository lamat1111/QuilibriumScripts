#!/bin/bash

# Script to update Quilibrium node

# Set the version number as a variable
VERSION="1.4.21.1"

# Change to the specified directory
echo "Changing to the ceremonyclient/node directory..."
cd $HOME/ceremonyclient/node || { echo "Failed to change directory. Exiting."; exit 1; }

# Download files
echo "Downloading new node files..."
files=(
    "node-$VERSION-linux-amd64"
    "node-$VERSION-linux-amd64.dgst"
)

for i in {1..17}; do
    files+=("node-$VERSION-linux-amd64.dgst.sig.$i")
done

for file in "${files[@]}"; do
    wget "https://releases.quilibrium.com/$file" -O "$file" || { echo "Failed to download $file. Exiting."; exit 1; }
done

echo "All files downloaded successfully."

# Make the new node executable
echo "Making the new node executable..."
chmod +x $HOME/ceremonyclient/node-$VERSION-linux-amd64 || { echo "Failed to make node executable. Exiting."; exit 1; }

# Stop the ceremonyclient service
echo "Stopping ceremonyclient service..."
sudo service ceremonyclient stop || { echo "Failed to stop ceremonyclient service. Exiting."; exit 1; }

# Update the service file
echo "Updating ceremonyclient service file..."
sudo sed -i "s|^ExecStart=.*|ExecStart=/root/ceremonyclient/node/node-$VERSION-linux-amd64|" /lib/systemd/system/ceremonyclient.service || { echo "Failed to update service file. Exiting."; exit 1; }

# Reload systemd
echo "Reloading systemd..."
sudo systemctl daemon-reload || { echo "Failed to reload systemd. Exiting."; exit 1; }

# Start the ceremonyclient service
echo "Starting ceremonyclient service..."
sudo service ceremonyclient start || { echo "Failed to start ceremonyclient service. Exiting."; exit 1; }

echo "Update completed successfully!"
