#!/bin/bash

# Script to update Quilibrium node
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

# Set the version number as a variable
VERSION="1.4.21.1"
NODE_DIR="$HOME/ceremonyclient/node"
NODE_BINARY="node-$VERSION-linux-amd64"

# Function to handle errors
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Display update plan
echo "==============================================="
echo "Quilibrium Node - downgrade to version $VERSION"
echo "==============================================="
echo
echo "This script will perform the following actions:"
echo "1. Create a backup of your current .config directory"
echo "2. Download the new node binary and signature files"
echo "3. Make the new node binary executable"
echo "4. Stop the ceremonyclient service"
echo "5. Update the service file to use the new binary"
echo "6. Reload systemd configuration"
echo "7. Start the ceremonyclient service with new version"
echo
echo "The update will be performed in: $NODE_DIR"
echo "New binary will be: $NODE_BINARY"
echo
echo "==============================================="
echo "Compatibility:"
echo "only compatible with nodes that are running via service file"
echo "only compatible with: os:linux arch:amd64 / ubuntu 22.x or 24.x"
echo "not compatible with node clusters"
echo
echo "DO NOT RUN THIS SCRIPT IF YOU ARE ALREADY ON v2.0.1"
echo
sleep 1

# Ask for confirmation
read -p "Do you want to proceed with the update? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 1
fi

# Verify directory exists
[ -d "$NODE_DIR" ] || error_exit "Directory $NODE_DIR does not exist"

# Check if service file exists
if [ ! -f "/lib/systemd/system/ceremonyclient.service" ]; then
    echo "Error: ceremonyclient service file not found."
    echo "This script is only compatible with nodes running via service file."
    exit 1
fi

# Stop the ceremonyclient service
echo "Stopping ceremonyclient service..."
systemctl stop ceremonyclient || error_exit "Failed to stop ceremonyclient service"

# Backup .config directory with progress and error checking
echo "Starting backup of .config directory..."
if [ -d "$NODE_DIR/.config" ]; then
    # Create a temporary backup first
    echo "Creating temporary backup..."
    rsync -av --progress "$NODE_DIR/.config/" "$NODE_DIR/.config.bak.tmp/" || {
        echo "Error: Temporary backup failed"
        rm -rf "$NODE_DIR/.config.bak.tmp"  # Clean up failed backup
        exit 1
    }
    
    # If temporary backup succeeded, remove old backup and move new one into place
    echo "Finalizing backup..."
    if [ -d "$NODE_DIR/.config.bak" ]; then
        rm -rf "$NODE_DIR/.config.bak" || {
            echo "Error: Could not remove old backup"
            rm -rf "$NODE_DIR/.config.bak.tmp"
            exit 1
        }
    fi
    
    mv "$NODE_DIR/.config.bak.tmp" "$NODE_DIR/.config.bak" || {
        echo "Error: Could not finalize backup"
        rm -rf "$NODE_DIR/.config.bak.tmp"
        exit 1
    }
    
    echo "Backup completed successfully"
else
    echo "Error: .config directory not found at $NODE_DIR/.config"
    exit 1
fi

# Change to the specified directory
echo "Changing to the ceremonyclient/node directory..."
cd "$NODE_DIR" || error_exit "Failed to change directory"

# Download files
echo "Downloading new node files..."

# Main files to download
main_files=(
    "$NODE_BINARY"
    "$NODE_BINARY.dgst"
)

# Signature files to download
sig_files=(
    "$NODE_BINARY.dgst.sig.1"
    "$NODE_BINARY.dgst.sig.2"
    "$NODE_BINARY.dgst.sig.3"
    "$NODE_BINARY.dgst.sig.8"
    "$NODE_BINARY.dgst.sig.9"
    "$NODE_BINARY.dgst.sig.13"
    "$NODE_BINARY.dgst.sig.15"
    "$NODE_BINARY.dgst.sig.16"
    "$NODE_BINARY.dgst.sig.17"
)

# Download all files using curl
for file in "${main_files[@]}" "${sig_files[@]}"; do
    echo "Downloading $file..."
    curl -# -L -o "$file" "https://releases.quilibrium.com/$file" || error_exit "Failed to download $file"
done

echo "File download process completed."

# Make the new node executable
echo "Making the new node executable..."
chmod +x "$NODE_BINARY" || error_exit "Failed to make node executable"

# Update the service file
echo "Updating ceremonyclient service file..."
sed -i "s|^ExecStart=.*|ExecStart=$NODE_DIR/$NODE_BINARY|" /lib/systemd/system/ceremonyclient.service || error_exit "Failed to update service file"

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload || error_exit "Failed to reload systemd"

# Start the ceremonyclient service
echo "Starting ceremonyclient service..."
systemctl start ceremonyclient || error_exit "Failed to start ceremonyclient service"

echo "Update to v$VERSION completed successfully!"
echo "Node started automatically"
echo
echo "Note: If you use the Q1 'check balance' menu option, you will see 0 balance."
echo "Please use this command instead:"
echo "cd $NODE_DIR && ./$NODE_BINARY -balance"