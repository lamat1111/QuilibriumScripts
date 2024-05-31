#!/bin/bash

# Exit on any error
set -e

# Define a function for displaying exit messages
exit_message() {
    echo "There was an error during the script execution and the process stopped. No worries!"
    echo "You can try to run the script from scratch again."
    echo "If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}

# Set a trap to call exit_message on any error
trap exit_message ERR

# Step 0: Welcome
echo "This script will install your Quilibrium node as a service and start it."
echo "Made with 🔥 by LaMat"
echo "Processing..."
sleep 7  # Add a 7-second delay

# Ensure Go is available
export GOPATH=$HOME/go
export GOROOT=/usr/local/go  # Adjust this path to where Go is installed
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Please install Go and try again."
    exit 1
fi

# Build binary file
echo "Building binary file"
cd ~/ceremonyclient/node
GOEXPERIMENT=arenas go install ./...

# Verify that the node executable exists
NODE_EXECUTABLE="$GOPATH/bin/node"
if [ ! -f "$NODE_EXECUTABLE" ]; then
    echo "Error: The node executable was not found at $NODE_EXECUTABLE"
    exit 1
fi

# Create Ceremonyclient Service
echo "Creating Ceremonyclient Service"
sleep 1  # Add a 1-second delay
sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/root/ceremonyclient/node
Environment=GOEXPERIMENT=arenas
ExecStart=$NODE_EXECUTABLE ./...

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Start the ceremonyclient service
echo "Starting Ceremonyclient Service"
sleep 1  # Add a 1-second delay
sudo systemctl enable ceremonyclient
sudo systemctl start ceremonyclient

# Final messages
echo "Now your node is running as a service!"
echo ""
echo "Now I will show below the node log..."
echo "To exit the log just type CTRL + C"

# See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
