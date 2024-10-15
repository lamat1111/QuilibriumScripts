#!/bin/bash

cat << "EOF"


                    Q1Q1Q1\    Q1\   
                   Q1  __Q1\ Q1Q1 |  
                   Q1 |  Q1 |\_Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1  Q1Q1 |  Q1 |  
                   \Q1Q1Q1 / Q1Q1Q1\ 
                    \___Q1Q\ \______|  QUILIBRIUM.ONE
                        \___|        
                              
===================================================================
                 ✨ RESTORE BACKUP FROM STORJ ✨
===================================================================
This script will restore your node backup from StorJ.

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

Processing... ⏳

EOF

sleep 3

# Prompt to proceed
echo "⚠️ This script will only work if you have used the corresponding"
echo "backup script to create the backup of your entire .config folder."
echo "Your node backup needs to be stored in 'storj:bucket/source_folder/.config',"
echo "where 'bucket' and 'source_folder' are your custom values."
echo
echo "If the above is correct, we can proceed."
read -p "Do you want to proceed? [y/n]: " proceed
if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
    echo "❌ Exiting the script."
    exit 1
fi

# Function to check if a package is installed
is_installed() {
    command -v "$1" &> /dev/null
}

# Function to install rclone
install_rclone() {
    if ! is_installed "rclone"; then
        echo "⌛️ Installing rclone..."
        sudo -v
        curl -s https://rclone.org/install.sh | sudo bash > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "❌ rclone installation failed."
            exit 1
        fi
        echo "✅ rclone installed successfully."
        sleep 1
    else
        echo "⚙️ rclone is already installed."
        sleep 1
    fi
}

# Install rclone if not installed
install_rclone

#====================
# RCLONE + STORJ CONFIGS
#====================

# Ensure rclone config directory exists
mkdir -p "$HOME/.config/rclone"

# Check if the rclone configuration file exists
if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
    echo "⚙️ Rclone configuration not found. Setting up rclone and StorJ configuration..."
    sleep 1
    
    # Prompt for StorJ secret key
    read -p "🔒 Enter your StorJ access key: " access_key
    read -p "🔒 Enter your StorJ SECRET key: " secret_key
    echo
    
    # Validate inputs
    if [[ -z "$access_key" || -z "$secret_key" ]]; then
        echo "❌ Access key or secret key cannot be empty. Exiting..."
        exit 1
    fi
    
    # Configure rclone with StorJ backend
    {
        echo "[storj]"
        echo "type = s3"
        echo "provider = Storj"
        echo "access_key_id = $access_key" 
        echo "secret_access_key = $secret_key"
        echo "endpoint = https://gateway.storjshare.io"
        echo "acl = private"
    } >> "$HOME/.config/rclone/rclone.conf"
    
    echo "✅ Rclone configured with StorJ backend."
    sleep 1
else
    echo "⚙️ Rclone configuration found. Checking for [storj] section..."
    sleep 1
    
    # Check if the [storj] section exists in rclone.conf
    if ! grep -q "^\[storj\]$" "$HOME/.config/rclone/rclone.conf"; then
        echo "⚙️ Adding [storj] section to existing rclone configuration..."
        sleep 1
        
        # Prompt for StorJ secret key
        read -p "▶️ Enter your StorJ access key: " access_key
        read -p "🔒 Enter your StorJ SECRET key: " secret_key
        echo
        
        # Validate inputs
        if [[ -z "$access_key" || -z "$secret_key" ]]; then
            echo "❌ Access key or secret key cannot be empty. Exiting..."
            exit 1
        fi
        
        # Append [storj] section to existing rclone configuration
        {
            echo "[storj]"
            echo "type = s3"
            echo "provider = Storj"
            echo "access_key_id = $access_key"
            echo "secret_access_key = $secret_key"
            echo "endpoint = https://gateway.storjshare.io"
            echo "acl = private"
        } >> "$HOME/.config/rclone/rclone.conf"
        
        echo "✅ [storj] section added to existing rclone configuration."
        sleep 1
    else
        echo "✅ [storj] section found in rclone configuration."
        sleep 1
        read -p "⚠️ Do you want to keep the existing StorJ access keys? [y/n]: " keep_keys
        if [[ "$keep_keys" == "N" || "$keep_keys" == "n" ]]; then
            # Prompt for new StorJ keys
            read -p "▶️ Enter your new StorJ access key: " access_key
            read -p "🔒 Enter your new StorJ SECRET key: " secret_key
            echo
            
            # Validate inputs
            if [[ -z "$access_key" || -z "$secret_key" ]]; then
                echo "❌ Access key or secret key cannot be empty. Exiting..."
                exit 1
            fi
            
            # Overwrite existing StorJ keys
            sed -i "/^access_key_id =/c\access_key_id = $access_key" "$HOME/.config/rclone/rclone.conf"
            sed -i "/^secret_access_key =/c\secret_access_key = $secret_key" "$HOME/.config/rclone/rclone.conf"
            
            echo "✅ StorJ access keys updated."
            sleep 1
        fi
    fi
fi


# Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl list-units --full -all | grep -Fq 'ceremonyclient.service'; then
    if systemctl is-active --quiet ceremonyclient; then
        if service ceremonyclient stop; then
            echo "🔴 Service stopped successfully."
        else
            echo "❌ Ceremonyclient service could not be stopped." >&2
        fi
    else
        echo "🟡 Ceremonyclient service is already stopped."
    fi
else
    echo "❌ Ceremonyclient service does not exist." >&2
fi
sleep 1

#====================
# RESTORE BACKUP
#====================

# Prompt for source folder on StorJ
read -p "▶️ Enter bucket name on StorJ to restore from: " bucket
read -p "▶️ Enter the source folder name on StorJ to restore from: " source_folder
echo

# Validate inputs
if [[ -z "$bucket" || -z "$source_folder" ]]; then
    echo "❌ Bucket name or source folder name cannot be empty. Exiting..."
    exit 1
fi

# Prompt for action on existing .config folder
echo "ℹ️ Now I will restore the whole .config folder from StorJ."
read -p "ℹ️ What do you want to do with your existing .config folder on this server?
1 - Back it up
2 - Remove it (this will delete your existing keys)
Choose an option [1/2]: " config_action

# Handle the existing .config folder based on user's choice
if [[ "$config_action" == "1" ]]; then
    echo "⚙️ Backing up existing .config folder..."
    mv ~/ceremonyclient/node/.config ~/ceremonyclient/node/.config.bak
    if [[ $? -ne 0 ]]; then
        echo "❌ Backup failed. Exiting..."
        exit 1
    fi
    echo "✅ Existing .config folder backed up as .config.bak."
    sleep 1
elif [[ "$config_action" == "2" ]]; then
    echo "⚠️ Removing existing contents from ~/ceremonyclient/node/.config/..."
    rm -rf ~/ceremonyclient/node/.config/*
    if [[ $? -ne 0 ]]; then
        echo "❌ Removal failed. Exiting..."
        exit 1
    fi
    echo "✅ Existing .config folder contents removed."
    sleep 1
else
    echo "❌ Invalid option. Exiting..."
    exit 1
fi

# Restore .config folder
echo "⌛️ Restoring backup from StorJ..."
rclone copy "storj:/$bucket/$source_folder/.config/" ~/ceremonyclient/node/.config/ --progress
if [[ $? -ne 0 ]]; then
    echo "❌ Restore failed. Exiting..."
    exit 1
fi
echo
echo "✅ .Config folder backup restored successfully."
echo
sleep 1

# Restore cron jobs
if check_file_exists "storj:/$bucket/$source_folder/cron_jobs.txt/cron_jobs.txt"; then
    echo "⌛️ Restoring your cron jobs..."
    rclone cat storj:/$bucket/$source_folder/cron_jobs.txt/cron_jobs.txt | crontab -
else
    echo "❌ Error: cron_jobs.txt not found on Storj. Skipping cron job restoration."
fi

# Restore scripts
if check_file_exists "storj:/$bucket/$source_folder/scripts"; then
    echo "⌛️ Restoring your custom scripts..."
    rclone sync storj:/$bucket/$source_folder/scripts ~/scripts
    echo "⌛️ Making all files in ~/scripts executable..."
    chmod +x ~/scripts/*
else
    echo "❌ Error: scripts folder not found on Storj. Skipping script restoration."
fi

# Show contents of restored .config folder
echo "✅ All done!"
echo "If there were cronjobs or custom scripts backups, I restored them as well."
echo
echo "✅ Here are the contents of your .config folder:"
echo "------------------------------------------------------------"
ls -la ~/ceremonyclient/node/.config/
echo "============================================================"
echo "⚠️ If you don't see your keys.yml and config.yml files,"
echo "it means you did not back them up via StorJ." 
echo "Please upload them manually before restarting your node."
echo
echo "Remember to restart your node service manually when you are done".
echo "============================================================"
echo
echo "✅ Here are the contents of your scripts folder:"
echo "------------------------------------------------------------"
ls -la ~/scripts/
echo "============================================================"
echo
echo "✅ Here are your existing cronjobs:"
echo "------------------------------------------------------------"
crontab -l
echo "============================================================"
echo

