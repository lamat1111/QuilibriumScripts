#!/bin/bash

# Step 0: Welcome

cat << "EOF"             
     QQQQQQQQQ       1111111   
   QQ:::::::::QQ    1::::::1   
 QQ:::::::::::::QQ 1:::::::1   
Q:::::::QQQ:::::::Q111:::::1   
Q::::::O   Q::::::Q   1::::1   
Q:::::O     Q:::::Q   1::::1   
Q:::::O     Q:::::Q   1::::1   
Q:::::O     Q:::::Q   1::::l   
Q:::::O     Q:::::Q   1::::l   
Q:::::O     Q:::::Q   1::::l   
Q:::::O  QQQQ:::::Q   1::::l   
Q::::::O Q::::::::Q   1::::l   
Q:::::::QQ::::::::Q111::::::111
 QQ::::::::::::::Q 1::::::::::1
   QQ:::::::::::Q  1::::::::::1
     QQQQQQQQ::::QQ111111111111
             Q:::::Q           
              QQQQQQ                                                                                                                                  
EOF
echo ""
echo ""
echo "==================================================================="
echo "                ✨ QNODE SERVICE INSTALLER ✨"
echo "==================================================================="
echo "This script will install your Quilibrum node as a service."
echo "Be sure to run the 'Server Setup' script first."
echo "Follow the guide at https://docs.quilibrium.one"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "===================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Exit on any error
set -e

# Step 1: Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "🔄 You can try to run the script from scratch again."
    echo "🛠️ If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}

# Function to install a package if it is not already installed
install_package() {
    echo "⏳ Installing $1..."
    if apt-get install -y $1; then
        echo "✅ $1 installed successfully."
    else
        echo "❌ Failed to install $1. You will have to do this manually."
    fi
}

# Install cpulimit
install_package cpulimit

# Install gawk
install_package gawk

echo "✅ cpulimit and gawk are installed and up to date."


# Step 2: Set a trap to call exit_message on any error
trap exit_message ERR

# Step 3: Backup existing configuration files if they exist
if [ -d ~/ceremonyclient ]; then
    mkdir -p ~/backup/qnode_keys
    [ -f ~/ceremonyclient/node/.config/keys.yml ] && cp ~/ceremonyclient/node/.config/keys.yml ~/backup/qnode_keys/ && echo "✅ Backup of keys.yml created in ~/backup/qnode_keys folder"
    [ -f ~/ceremonyclient/node/.config/config.yml ] && cp ~/ceremonyclient/node/.config/config.yml ~/backup/qnode_keys/ && echo "✅ Backup of config.yml created in ~/backup/qnode_keys folder"
fi

# Step 4: Download Ceremonyclient
echo "⏳ Downloading Ceremonyclient"
sleep 1  # Add a 1-second delay
cd ~
if [ -d "ceremonyclient" ]; then
  echo "Directory ceremonyclient already exists, skipping git clone..."
else
  attempt=0
  max_attempts=3
  while [ $attempt -lt $max_attempts ]; do
    if git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://source.quilibrium.com/quilibrium/ceremonyclient.git"
      break
    elif git clone https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git"
      break
    elif git clone https://github.com/QuilibriumNetwork/ceremonyclient.git; then
      echo "✅ Successfully cloned from https://github.com/QuilibriumNetwork/ceremonyclient.git"
      break
    else
      attempt=$((attempt+1))
      echo "Git clone failed (attempt $attempt of $max_attempts), retrying..."
      sleep 2
    fi
  done

  if [ $attempt -ge $max_attempts ]; then
    echo "❌ Error: Failed to clone the repository after $max_attempts attempts." >&2
    exit 1
  fi
fi

cd ~/ceremonyclient/
git checkout release

# Set up environment variables (redundant but solves the command go not found error)
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Step 4.1: Build Ceremonyclient qClient
echo "⏳ Building qClient..."
sleep 1  # Add a 1-second delay
cd ~/ceremonyclient/client
GOEXPERIMENT=arenas go build -o qclient main.go

# Step 5: Determine the ExecStart line based on the architecture
# Get the current user's home directory
HOME=$(eval echo ~$USER)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Step 6: Create Ceremonyclient Service
echo "⏳ Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay

# Check if the file exists before attempting to remove it
if [ -f "/lib/systemd/system/ceremonyclient.service" ]; then
    rm /lib/systemd/system/ceremonyclient.service
    echo "ceremonyclient.service file removed."
else
    echo "ceremonyclient.service file does not exist. No action taken."
fi

sudo tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=$NODE_PATH
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"

sleep 2  # Add a 2-second delay
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient
sudo service ceremonyclient start

# Step 8: Final messages
echo "🎉 Now your node is starting!"
echo "🕒 Let it run for at least 30 minutes to generate your keys."
echo ""
echo "🔐 You can logout of your server if you want and login again later."
echo "🔒 After 30 minutes, backup your keys.yml and config.yml files."
echo "ℹ️ More info about this in the online guide: https://docs.quilibrium.one"
echo ""
echo "📜 Now I will show the node log below..."
echo "To exit the log, just type CTRL +C."

# Step 9: See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
