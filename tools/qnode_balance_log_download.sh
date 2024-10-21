#!/bin/bash

# Script version
SCRIPT_VERSION="1.2"

# Function to check for newer script version
check_for_updates() {
    #echo "⚙️ Checking for script updates..."
    LATEST_VERSION=$(wget -qO- "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_log_download.sh" | grep 'SCRIPT_VERSION="' | head -1 | cut -d'"' -f2)
    if [ "$SCRIPT_VERSION" != "$LATEST_VERSION" ]; then
        wget -O ~/scripts/qnode_balance_log_download.sh "https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_balance_log_download.sh"
        chmod +x ~/scripts/qnode_balance_log_download.sh
        echo "✅ New version downloaded: V $SCRIPT_VERSION."
        echo
        sleep 1
    fi
}

# Check for updates and update if available
check_for_updates

# Function to check and install Python 3 if not already installed
check_python3() {
    if ! command -v python3 &> /dev/null; then
        echo "⌛️ Python 3 is not installed. Installing it now..."
        sudo apt update
        sudo apt install -y python3
        echo "Python 3 installed successfully."
        echo
    fi
}

# Check if the script is run as root
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Get the external IP address
IP_ADDRESS=$(curl -s -4 icanhazip.com)

# Function to find an available port
find_available_port() {
  while true; do
    PORT=$(shuf -i 1025-65535 -n 1)
    if ! lsof -i:$PORT > /dev/null; then
      echo $PORT
      return
    fi
  done
}

# Find a random available port above 1024
PORT=$(find_available_port)

# Variables to track if we opened the port
UFW_OPENED=false
FIREWALL_CMD_OPENED=false

# Check if the firewall is blocking the port and open it if necessary
if command -v ufw > /dev/null 2>&1; then
  # Check if ufw is enabled
  if $SUDO ufw status | grep -q "Status: active"; then
    # Check if the port is allowed
    if ! $SUDO ufw status | grep -q "$PORT/tcp"; then
      #cho "Opening port $PORT in the firewall..."
      $SUDO ufw allow $PORT/tcp > /dev/null 2>&1
      UFW_OPENED=true
    fi
  fi
elif command -v firewall-cmd > /dev/null 2>&1; then
  # Check if firewalld is running
  if $SUDO firewall-cmd --state | grep -q "running"; then
    # Check if the port is allowed
    if ! $SUDO firewall-cmd --list-ports | grep -q "$PORT/tcp"; then
      #echo "Opening port $PORT in the firewall..."
      $SUDO firewall-cmd --add-port=$PORT/tcp --permanent > /dev/null 2>&1
      $SUDO firewall-cmd --reload > /dev/null 2>&1
      FIREWALL_CMD_OPENED=true
    fi
  fi
else
  echo "No recognized firewall management tool found."
fi

# Function to clean up and exit
cleanup() {
  echo "Stopping the web server and cleaning up..."
  kill $SERVER_PID

  # Close the port if it was opened by this script
  if $UFW_OPENED; then
    echo "Closing port $PORT in the firewall..."
    $SUDO ufw delete allow $PORT/tcp > /dev/null 2>&1
  fi

  if $FIREWALL_CMD_OPENED; then
    echo "Closing port $PORT in the firewall..."
    $SUDO firewall-cmd --remove-port=$PORT/tcp --permanent > /dev/null 2>&1
    $SUDO firewall-cmd --reload > /dev/null 2>&1
  fi
}

# Trap SIGINT (Ctrl+C) and call cleanup function
trap "echo 'Then press ENTER to stop the web server.'; trap - SIGINT" SIGINT

# Start a temporary web server
#echo "Starting temporary web server on port $PORT..."
cd $HOME/scripts
python3 -m http.server $PORT > /dev/null 2>&1 &
SERVER_PID=$!

# Open port in UFW
sudo ufw allow $PORT/tcp

# Give URL for downloading
echo
DOWNLOAD_URL="http://$IP_ADDRESS:$PORT/balance_log.csv"
echo "✅ Copy or click the below URL to download your balance log"
echo "$DOWNLOAD_URL"

# Provide instructions for copying the URL
echo
echo "Then press ENTER to stop the web server."

# Wait for the user to press Enter
read -p ""

# Call cleanup function
cleanup
