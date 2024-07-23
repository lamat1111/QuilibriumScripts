#!/bin/bash -i

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
echo "==========================================================================="
echo "                       ✨ QNODE SERVER SETUP ✨"
echo "==========================================================================="
echo "This script will prepare your server for the Quilibrium node installation."
echo "Follow the guide at https://docs.quilibrium.one"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "==========================================================================="
echo ""
echo "⏳ Processing... "
sleep 7  # Add a 7-second delay


# Define a function for displaying exit messages
exit_message() {
    echo
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "You can try to run the script from scratch again."
    echo "If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
    fi
fi

# Check sudo availability
if ! [ -x "$(command -v sudo)" ]; then
  echo "⚠️ Sudo is not installed! This script requires sudo to run. Exiting..."
  exit_message
  exit 1
fi

#################################
# APPS
#################################

# Update and Upgrade the Machine
echo "⏳ Updating the machine..."
echo "⏳ Processing... "
sleep 2  # Add a 2-second delay
sudo apt-get update -y && sudo apt-get upgrade -y

# Install required packages
echo "⏳ Installing useful packages..."

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Install git, wget, tar and exit if it fails
for pkg in git wget tar; do
    if ! is_installed "$pkg"; then
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg" > /dev/null 2>&1 || { echo "❌ Failed to install $pkg! These are necessary apps, so I will exiting..."; exit_message; exit 1; }
    else
        echo "$pkg is already installed."
    fi
done

# Install tmux, cron and jq and move on if it fails
for pkg in tmux cron jq; do
    if ! is_installed "$pkg"; then
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg" > /dev/null 2>&1 || { echo "❌ Failed to install $pkg! These are optional apps, so I will continue..."; }
    else
        echo "$pkg is already installed."
    fi
done

echo "✅ All packages installed successfully or already present."
echo

#################################
# GO
#################################


# Installing Go
echo "⏳ Downloading and installing GO..."
wget https://go.dev/dl/$GO_BINARY > /dev/null 2>&1 || echo "❌ Failed to download GO!"    
sudo tar -xvf $GO_BINARY > /dev/null 2>&1 || echo "❌ Failed to extract GO!"
sudo rm -rf /usr/local/go || echo "❌ Failed to remove existing GO!"
sudo mv go /usr/local || echo "❌ Failed to move GO!"
sudo rm $GO_BINARY || echo "❌ Failed to remove downloaded archive!"

# Set Go environment variables
echo "⏳ Setting Go environment variables..."

# Check if PATH is already set
if grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc; then
    echo "✅ PATH already set in ~/.bashrc."
else
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo "✅ PATH set in ~/.bashrc."
fi

# Check if GOPATH is already set
if grep -q "export GOPATH=$HOME/go" ~/.bashrc; then
    echo "✅ GOPATH already set in ~/.bashrc."
else
    echo "export GOPATH=$HOME/go" >> ~/.bashrc
    echo "✅ GOPATH set in ~/.bashrc."
fi

# Check if GO111MODULE is already set
if grep -q "export GO111MODULE=on" ~/.bashrc; then
    echo "✅ GO111MODULE already set in ~/.bashrc."
else
    echo "export GO111MODULE=on" >> ~/.bashrc
    echo "✅ GO111MODULE set in ~/.bashrc."
fi

# Check if GOPROXY is already set
if grep -q "export GOPROXY=https://goproxy.cn,direct" ~/.bashrc; then
    echo "✅ GOPROXY already set in ~/.bashrc."
else
    echo "export GOPROXY=https://goproxy.cn,direct" >> ~/.bashrc
    echo "✅ GOPROXY set in ~/.bashrc."
fi
echo

# Source .bashrc to apply changes
source ~/.bashrc
sleep 1  # Add a 1-second delay

# Step 6: Adjust network buffer sizes
echo "⏳ Adjusting network buffer sizes..."
if grep -q "^net.core.rmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.rmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.rmem_max=600000000" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
if grep -q "^net.core.wmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.wmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.wmem_max=600000000" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
sudo sysctl -p
echo

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#################################
# gRPCurl
#################################

# Install gRPCurl
echo "⏳ Installing gRPCurl..."
sleep 1  # Add a 1-second delay

# Try installing gRPCurl using go install
if go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest; then
    echo "✅ gRPCurl installed successfully via go install."
    echo
else
    echo "❌ Failed to install gRPCurl via go install. Trying apt-get..."
    # Try installing gRPCurl using apt-get
    if sudo apt-get install grpcurl -y; then
        echo "✅ gRPCurl installed successfully via apt-get."
        echo
    else
        echo "❌ Failed to install gRPCurl via apt-get! Moving on to the next step..."
        echo
        # Optionally, perform additional error handling here
    fi
fi

#################################
# UFW FIREWALL
#################################

# Install ufw and configure firewall
echo "⏳ Installing ufw (Uncomplicated Firewall)..."
sudo apt-get update
sudo apt-get install ufw -y || { echo "❌ Failed to install ufw! Moving on to the next step..."; }

# Attempt to enable ufw
echo "⏳ Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    echo "y" | sudo ufw enable || { echo "❌ Failed to enable firewall! No worries, you can do it later manually."; }
else
    echo "⚠️ ufw (Uncomplicated Firewall) is not installed. Skipping firewall configuration."
fi

# Check if ufw is available and configured
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
    # Allow required ports
    for port in 22 8336 443; do
        if ! ufw_rule_exists "${port}"; then
            sudo ufw allow "${port}" || echo "⚠️ Error: Failed to allow port ${port}! You will need to allow port 8336 manually for the node to connect."
        fi
    done

    # Display firewall status
    sudo ufw status
    echo "✅ Firewall setup was successful."
    echo
else
    echo "⚠️ Failed to configure firewall or ufw is not installed. No worries, you can do it later manually. Moving on to the next step..."
    echo
fi

#################################
# FAIL2BAN
#################################

echo "⏳ Installing Fail2ban to protect you from brute force attacks..."

# Function to log errors
log_error() {
    echo "❌ Error: $1" >&2
}

# Check if Fail2Ban is already installed
if dpkg -s fail2ban &> /dev/null; then
    echo "✅ Fail2Ban is already installed. Skipping installation."
else
    # Install Fail2Ban
    if ! sudo apt install fail2ban -y; then
        log_error "Failed to install Fail2Ban. Skipping configuration."
    else
        echo "✅ Fail2Ban has been successfully installed."
    fi
fi

# Only proceed with configuration if Fail2Ban is installed
if dpkg -s fail2ban &> /dev/null; then
    # Check if a custom configuration already exists
    if [ -f "/etc/fail2ban/jail.d/sshd.conf" ]; then
        echo "⚠️ Custom Fail2Ban configuration already exists. Skipping configuration."
    else
        # Create a backup of the original jail.conf file
        sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.backup

        # Create SSH jail configuration
        if ! cat << EOF | sudo tee /etc/fail2ban/jail.d/sshd.conf > /dev/null
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
findtime = 300
bantime = 1800
EOF
        then
            log_error "Failed to create custom Fail2Ban configuration."
        else
            echo "✅ Custom Fail2Ban configuration has been created."
        fi

        # Restart Fail2Ban to apply changes
        if ! sudo systemctl restart fail2ban; then
            log_error "Failed to restart Fail2Ban service."
        else
            echo "✅ Fail2Ban service has been restarted."
        fi

        # Enable Fail2Ban to start on boot
        if ! sudo systemctl enable fail2ban; then
            log_error "Failed to enable Fail2Ban service on boot."
        else
            echo "✅ Fail2Ban has been enabled to start on boot."
        fi
    fi
else
    echo "⚠️ Fail2Ban is not installed. Skipping configuration."
fi

echo "✅ Fail2Ban installation and configuration process completed."
echo

#################################
# FINISH
#################################

# Creating some useful folders
echo "⏳ Creating backup, scripts and scripts/log folders..."
sudo mkdir -p /root/backup/
sudo mkdir -p /root/scripts/
sudo mkdir -p /root/scripts/log/
echo "✅ Folders created."
echo

# Prompt for reboot
echo "🎉 Server setup is finished!"
echo ""
echo "🟡 YOU NEED TO REBOOT YOUR SERVER NOW 🟡"
echo "Type 'sudo reboot' and press ENTER to reboot your server."
echo ""
echo "Then follow the online guide for the next steps"
echo "to install your Quilibrium node as a service: https://docs.quilibrium.one" 
sleep 7
