#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will update your Quilibrium node when running it as a service. ✨"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Step 1: Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl is-active --quiet ceremonyclient && service ceremonyclient stop; then
    echo "🔴 Service stopped successfully."
else
    echo "❌ Ceremonyclient service either does not exist or could not be stopped." >&2
fi
sleep 1

# Step 2: Move to the ceremonyclient directory
echo "📂 Moving to the ceremonyclient directory..."
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient does not exist."; exit 1; }

# Function to install a package if it is not already installed
install_package() {
    echo "⏳ Installing $1..."
    if apt-get install -y "$1"; then
        echo "✅ $1 installed successfully."
    else
        echo "❌ Failed to install $1. You will have to do this manually." >&2
    fi
}

# Install required packages
install_package cpulimit
install_package gawk

echo "✅ cpulimit and gawk are installed and up to date."

# Step 4: Download Binary
echo "⏳ Downloading New Release..."

# Temporarily mark the file as assume unchanged
git update-index --assume-unchanged node/release_autostart.sh

# Set the remote URL and verify access
for url in \
    "https://source.quilibrium.com/quilibrium/ceremonyclient.git" \
    "https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git" \
    "https://github.com/QuilibriumNetwork/ceremonyclient.git"; do
    if git remote set-url origin "$url" && git fetch origin; then
        echo "✅ Remote URL set to $url"
        break
    fi
done

# Check if the URL was set and accessible
if ! git remote -v | grep -q origin; then
    echo "❌ Error: Failed to set and access remote URL." >&2
    exit 1
fi

# Check if release_autostart.sh has changed in the latest commit
if git diff --name-only origin/release | grep -q "node/release_autostart.sh"; then
    echo "📄 release_autostart.sh has changed. Downloading the new version as release_autostart_remote.sh."
    git checkout origin/release -- node/release_autostart.sh
    cp node/release_autostart.sh node/release_autostart_remote.sh
    # Revert to your local version
    git checkout -- node/release_autostart.sh

    # Read both files into arrays
    mapfile -t local_lines < node/release_autostart.sh
    mapfile -t remote_lines < node/release_autostart_remote.sh

    # Function to extract cpulimit commands
    extract_cpulimit() {
        grep -o 'cpulimit -l [0-9]\{1,3\}' <<< "$1"
    }

    # Extract cpulimit commands
    local_cpulimits=()
    remote_cpulimits=()
    for line in "${local_lines[@]}"; do
        local_cpulimits+=( $(extract_cpulimit "$line") )
    done
    for line in "${remote_lines[@]}"; do
        remote_cpulimits+=( $(extract_cpulimit "$line") )
    done

    # Update remote cpulimit commands with local ones if they differ
    if [ "${#local_cpulimits[@]}" -eq "${#remote_cpulimits[@]}" ]; then
        for ((i = 0; i < ${#local_cpulimits[@]}; i++)); do
            if [ "${local_cpulimits[i]}" != "${remote_cpulimits[i]}" ]; then
                remote_lines=("${remote_lines[@]/${remote_cpulimits[i]}/${local_cpulimits[i]}}")
            fi
        done
    else
        echo "❌ Error: Mismatched number of cpulimit commands. Please check the files manually." >&2
        exit 1
    fi

    # Write the updated remote lines back to release_autostart_remote.sh
    printf "%s\n" "${remote_lines[@]}" > node/release_autostart_remote.sh

    # Rename files
    [ -f node/release_autostart.sh.bak ] && rm node/release_autostart.sh.bak
    mv node/release_autostart.sh node/release_autostart.sh.bak
    mv node/release_autostart_remote.sh node/release_autostart.sh

else
    echo "✅ release_autostart.sh has not changed."
fi

# Pull the latest changes
git pull || { echo "❌ Error: Failed to download the latest changes." >&2; exit 1; }
git checkout release || { echo "❌ Error: Failed to checkout release." >&2; exit 1; }

# Revert the assume unchanged mark
git update-index --no-assume-unchanged node/release_autostart.sh

echo "✅ Downloaded the latest changes successfully."

# Get the current user's home directory
HOME=$(eval echo ~$HOME_DIR)

# Use the home directory in the path
NODE_PATH="$HOME/ceremonyclient/node"
EXEC_START="$NODE_PATH/release_autorun.sh"

# Step 5: Re-Create or Update Ceremonyclient Service
echo "🔧 Rebuilding Ceremonyclient Service..."
sleep 2  # Add a 2-second delay
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "📝 Creating new ceremonyclient service file..."
    if ! sudo tee "$SERVICE_FILE" > /dev/null <<EOF
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
    then
        echo "❌ Error: Failed to create ceremonyclient service file." >&2
        exit 1
    fi
else
    echo "🔍 Checking existing ceremonyclient service file..."

    # Check if the required lines exist, if they are different, or if CPUQuota exists
    if ! grep -q "WorkingDirectory=$NODE_PATH" "$SERVICE_FILE" || ! grep -q "ExecStart=$EXEC_START" "$SERVICE_FILE" || grep -q '^CPUQuota=[0-9]*%' "$SERVICE_FILE"; then
        echo "🔄 Updating existing ceremonyclient service file..."
        # Replace the existing lines with new values
        sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=$NODE_PATH|" "$SERVICE_FILE"
        sudo sed -i "s|ExecStart=.*|ExecStart=$EXEC_START|" "$SERVICE_FILE"
        # Remove any line containing CPUQuota=x%
        if grep -q '^CPUQuota=[0-9]*%' "$SERVICE_FILE"; then
            echo "✅ CPUQuota line found. Deleting..."
            sudo sed -i '/^CPUQuota=[0-9]*%/d' "$SERVICE_FILE"
            echo "✅ CPUQuota line deleted. You don't need this anymore!"
        fi
    else
        echo "✅ No changes needed."
    fi
fi

# Step 6: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Showing the node logs
echo "🌟Your Qnode is now updated!"
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo ""
echo ""
sleep 3  # Add a 3-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
