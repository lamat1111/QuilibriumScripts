#!/bin/bash -i

GO_VERSION=1.23.2

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
        GO_BINARY="go$GO_VERSION.linux-amd64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go$GO_VERSION.darwin-amd64.tar.gz"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        GO_BINARY="go$GO_VERSION.linux-arm64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go$GO_VERSION.darwin-arm64.tar.gz"
    fi
fi

# Check sudo availability
if ! [ -x "$(command -v sudo)" ]; then
  echo "⚠️ Sudo is not installed! This script requires sudo to run. Exiting..."
  exit_message
  exit 1
fi


#################################
# USEFUL FUNCTIONS
#################################

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to log errors (reusable throughout the script)
log_error() {
    echo "❌ Error: $1" >&2
}

# Function to install a package if not already installed
install_package() {
    if ! is_installed "$1"; then
        echo "Installing $1..."
        sudo apt install -y "$1" > /dev/null 2>&1 || log_error "Failed to install $1"
    else
        echo "$1 is already installed."
    fi
}

# Function to add a line to a file if it doesn't exist
add_line_to_file() {
    if ! grep -q "$1" "$2"; then
        echo "$1" >> "$2"
        echo "✅ Added '$1' to $2."
    else
        echo "✅ '$1' already exists in $2."
    fi
}

#################################
# HOSTNAME CHANGE
#################################

# Display current hostname
echo
current_hostname=$(hostname)
echo "Current hostname is: $current_hostname"

# Ask if user wants to change the hostname
read -p "Do you want to change it? (y/n): " answer

if [[ $answer == "y" || $answer == "Y" ]]; then
    # Prompt for new hostname
    read -p "Enter new hostname: " new_hostname
    
    # Change the hostname
    sudo hostnamectl set-hostname "$new_hostname"
    
    echo "✅  Hostname changed to: $new_hostname"
else
    echo "✅  Hostname not changed."
fi
echo


#################################
# APPS
#################################

# Update and Upgrade the Machine
echo "⏳ Updating the machine..."
sleep 2  # Add a 2-second delay
sudo apt update -y && sudo apt upgrade -y
echo "✅ Machine updated."
echo

# Install required packages

echo "⏳ Installing: git wget tar curl..."
for pkg in git wget tar curl; do
    install_package "$pkg" || { echo "These are necessary apps, so I will exit..."; exit_message; exit 1; }
done
echo "✅ Packages installed successfully or already present."
echo

echo "⏳ Installing: tmux cron jq..."
for pkg in tmux cron jq htop; do
    install_package "$pkg" || echo "These are optional apps, so I will continue..."
done
echo "✅ Packages installed successfully or already present."
echo

#==========================
# GO UPGRADE
#==========================

# Check the currently installed Go version
if go version &>/dev/null; then
    INSTALLED_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
else
    INSTALLED_VERSION="none"
fi

# If the installed version is not $GO_VERSION, proceed with the installation
if [ "$INSTALLED_VERSION" != "$GO_VERSION" ]; then
    echo "⏳ Current Go version is $INSTALLED_VERSION. Proceeding with installation of Go $GO_VERSION..."

    # Download and install Go
    wget https://go.dev/dl/$GO_BINARY > /dev/null 2>&1 || echo "Failed to download Go!"
    sudo tar -xvf $GO_BINARY > /dev/null 2>&1 || echo "Failed to extract Go!"
    sudo rm -rf /usr/local/go || echo "Failed to remove existing Go!"
    sudo mv go /usr/local || echo "Failed to move Go!"
    sudo rm $GO_BINARY || echo "Failed to remove downloaded archive!"
    
    echo "✅ Go $GO_VERSION has been installed successfully."
else
    echo "✅ Go version $GO_VERSION is already installed. No action needed."
fi
echo

# Set Go environment variables
echo "⏳ Setting Go environment variables..."
add_line_to_file 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc
add_line_to_file "export GOPATH=$HOME/go" ~/.bashrc
add_line_to_file "export GO111MODULE=on" ~/.bashrc
add_line_to_file "export GOPROXY=https://goproxy.cn,direct" ~/.bashrc
echo

# Source .bashrc to apply changes
source ~/.bashrc
sleep 1  # Add a 1-second delay

# Adjust network buffer sizes
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
    echo "❌ Failed to install gRPCurl via go install. Trying apt install..."
    # Try installing gRPCurl using apt install
    if sudo apt install grpcurl -y; then
        echo "✅ gRPCurl installed successfully via apt install."
        echo
    else
        echo "❌ Failed to install gRPCurl via apt install! Moving on to the next step..."
        echo
        # Optionally, perform additional error handling here
    fi
fi

#################################
# UFW FIREWALL
#################################

# Install ufw and configure firewall
echo "⏳ Installing ufw (Uncomplicated Firewall)..."
sudo apt install ufw -y || { echo "❌ Failed to install ufw! Moving on to the next step..."; }

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

# Check if Fail2Ban is already installed
if ! is_installed "fail2ban"; then
    install_package "fail2ban" || log_error "Failed to install Fail2Ban. Skipping configuration."
else
    echo "✅ Fail2Ban is already installed. Skipping installation."
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
echo "✅ Server setup is finished!"
echo
echo "🟡 YOU NEED TO REBOOT YOUR SERVER NOW 🟡"
echo "Type 'sudo reboot' and press ENTER to reboot your server."
echo
echo "Then follow the online guide for the next steps"
echo "to install your Quilibrium node as a service: https://docs.quilibrium.one" 
sleep 7
