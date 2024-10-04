#!/bin/bash

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
                               QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


==========================================================================
                    ✨ NODE BACKUP VIA STORJ ✨
==========================================================================
This script automates the backup of your node data to StorJ.

You need a Storj account https://www.storj.io/ 
and a Public/Secret access key.

For security we suggest you to create a bucket specific to Quilibrium, 
and specific keys for accessing only that bucket.

To create your Keys on STorJ: "Access Keys > S3 Credentials"

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 7 # add sleep time

# Function to check for newer script version and update
check_for_updates() {
    SCRIPT_CHECKSUM=$(md5sum ~/scripts/qnode_backup_storj.sh | awk '{ print $1 }')
    LATEST_CHECKSUM=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_storj.sh | md5sum | awk '{ print $1 }')

    if [ "$SCRIPT_CHECKSUM" != "$LATEST_CHECKSUM" ]; then
        echo "Updating the script to the latest version..."
        sleep 1
        curl -o ~/scripts/qnode_backup_storj.sh https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_backup_storj.sh  || display_error "❌ Failed to download the newer version of the script."
        chmod +x ~/scripts/qnode_backup_storj.sh || display_error "❌ Failed to set execute permission for the updated script."
        echo "✅ Script updated successfully."
        sleep 1
        echo "Please run the script again."
        exit 0
    fi
}

# Check for updates and update if available
check_for_updates

# ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# Function to validate bucket names
validate_bucket_name() {
    if [[ ! $1 =~ ^[a-zA-Z0-9.-]+$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate backup type choice
validate_backup_choice() {
    if [[ "$1" == "1" || "$1" == "2" ]]; then
        return 0
    fi
    return 1
}

# Function to determine backup type based on user's choice
get_backup_type() {
    if [[ "$1" == "1" ]]; then
        echo "sync"
    else
        echo "copy"
    fi
}

#====================
# USER PROMPTS
#====================

# Prompt the user for StorJ S3 credentials
echo
echo
read -p "🔒 Enter your StorJ access key: " access_key
read -p "🔒 Enter your StorJ SECRET key: " secret_key
echo

# Initialize a flag to check if a new bucket needs to be created
create_bucket_flag=false

# Check if the user already has a StorJ bucket
echo
echo "If you don't have an existing bucket, you can create one now, BUT the keys you entered earlier"
echo "must grant general write access to your StorJ account."
echo "In general, it's better to create a bucket in the StorJ dashboard"
echo "and then create exclusive keys for that bucket."
echo

read -p "❔ Do you already have a StorJ bucket? (y/n): " has_bucket
if [[ $has_bucket =~ ^[Yy]$ ]]; then
    while true; do
        read -p "▶️ Enter your StorJ bucket name: " bucket
        echo
        if validate_bucket_name "$bucket"; then
            break
        else
            echo "❌ Invalid bucket name. It must contain only lowercase letters, numbers, dots, and hyphens."
        fi
    done
else
    echo "Create a new StorJ bucket using lowercase characters [a-z][0-9][-.]"
    while true; do
        read -p "▶️ Enter your StorJ bucket name: " bucket
        echo
        if validate_bucket_name "$bucket"; then
            create_bucket_flag=true
            break
        else
            echo "❌ Invalid bucket name. It must contain only lowercase letters, numbers, dots, and hyphens."
        fi
    done
fi

# Prompt for the target folder name
echo "Enter the target folder name where you want to store this backup, must be unique for each node!"
echo "Only lowercase characters [a-z][0-9][-.]"
read -p "▶️ Enter the target folder name, e.g., 'quil-01': " target_folder
echo

# Prompt for the backup choice
echo "❔ What kind of backup do you want to create?"
#echo "If you chose to backup your keys, these will be always be copied and not synced for security."
echo
echo "1. Sync: files on StorJ will be deleted if they are deleted on the source."
echo "2. Copy: files on StorJ will never be deleted."
read -p "▶️ Enter your choice (1 or 2): " backup_choice
while ! validate_backup_choice "$backup_choice"; do
    echo "❌ Invalid choice. Please enter '1' for sync or '2' for copy."
    read -p "▶️ Enter your choice (1 or 2): " backup_choice
done

# Determine backup type based on the user's choice
backup_type=$(get_backup_type "$backup_choice")

# Output the provided details for confirmation
echo
echo "Your backups for this node will be stored in '$bucket/$target_folder/'"
echo "Backup type selected: $backup_type"
echo


#====================
# APPS INSTALLATION 
#====================

# Function to check if a package is installed
is_installed() {
    command -v "$1" &> /dev/null
}

# Function to install a package
install_package() {
    pkg=$1
    if ! is_installed "$pkg"; then
        echo "⌛️ Installing $pkg..."
        sudo apt install -y "$pkg" > /dev/null 2>&1 || { echo "❌ Failed to install $pkg! This is a necessary app, so I will exit..."; exit_message; exit 1; }
        echo "✅ $pkg installed successfully."
    else
        echo "$pkg is already installed."
    fi
}

# Install curl if not installed
install_package "curl"

# Install cron if not installed
install_package "cron"

# Function to install rclone
install_rclone() {
    if ! is_installed "rclone"; then
        echo "⌛️ Installing rclone..."
        sudo -v
        curl -s https://rclone.org/install.sh | sudo bash > /dev/null
        echo "✅ rclone installed successfully."
    else
        echo "rclone is already installed."
    fi
}

# Install rclone if not installed
install_rclone

echo "✅ All packages installed successfully or already present."

#====================
# RCLONE + STORJ CONFIGS
#====================


# Ensure rclone config directory exists
mkdir -p $HOME/.config/rclone

# Check if the rclone configuration file exists
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    # Remove existing StorJ bucket configuration
    sed -i '/^\[storj\]/,/^$/d' "$HOME/.config/rclone/rclone.conf"
fi

# Configure StorJ bucket using S3
{
    echo "[storj]"
    echo "type = s3"
    echo "provider = Storj"
    echo "access_key_id = $access_key"
    echo "secret_access_key = $secret_key"
    echo "endpoint = https://gateway.storjshare.io"
    echo "acl = private"
} >> $HOME/.config/rclone/rclone.conf

# Check if rclone needs to create the new bucket and do it
if [[ $create_bucket_flag == true ]]; then
    echo "⌛️ Creating your StorJ bucket..."
    if rclone mkdir storj:$bucket; then
        echo "✅ StorJ bucket created successfully."
    else
        echo "❌ Failed to create StorJ bucket. Exiting script."
        exit 1
    fi
fi

# Backup node keys.yml and config.yml if selected
echo "It's not very secure to backup your keys as an object on StorJ, but if you want to do it, here you are..."
echo
read -p "❔ Do you want to backup your node 'keys.yml' and 'config.yml' files? (y/n): " backup_keys
if [[ $backup_keys =~ ^[Yy]$ ]]; then
    echo "⌛️ Copying node 'keys.yml' and 'config.yml' files... (I will back up these only once)."
    rclone copy $HOME/ceremonyclient/node/.config/keys.yml storj:/$bucket/$target_folder/.config/
    rclone copy $HOME/ceremonyclient/node/.config/config.yml storj:/$bucket/$target_folder/.config/
    echo "✅ Your keys are now backed up in 'storj:/$bucket/$target_folder/.config"
    echo "Your keys are backed up only once."
    echo
fi

#!/bin/bash

#====================
# CRONJOBS SETUP
#====================

# Function to add or update cron jobs
add_or_update_cronjob() {
    local cron_command="$1"
    local cron_schedule="$2"
    local existing_pattern="$3"
    
    # Remove existing cron job if it exists
    crontab -l | grep -v "$existing_pattern" | crontab -
    
    # Add the new/updated cron job
    (crontab -l; echo "$cron_schedule $cron_command") | crontab -
}

# Function to perform immediate backup
perform_backup() {
    local command="$1"
    eval "$command"
}

# Backup node store folder if selected
read -p "❔ Do you want to setup a recurring backup for your 'node/.config' folder? (y/n): " backup_node_folder
if [[ $backup_node_folder =~ ^[Yy]$ ]]; then
    # Prompt user for backup interval
    read -p "▶️ Backup 'node/.config' folder every how many hours? (1-100): " backup_interval

    # Generate a random minute for the cron job
    random_minute=$(shuf -i 0-59 -n 1)

    # Define the cron schedule
    cron_schedule="$random_minute */$backup_interval * * *"

    # Define the cron command
    cron_command="rclone $backup_type --transfers 10 --checkers 20 --disable-http2 --retries 1 --filter '+ store/**' --filter '+ store' --filter '- SELF_TEST' --filter '- keys.yml' --filter '- config.yml' /root/ceremonyclient/node/.config/ storj:/$bucket/$target_folder/.config/"

    # Pattern to check if the cron job already exists
    existing_store_pattern="/ceremonyclient/node/.config/ storj:"

    # Add or update the cron job
    add_or_update_cronjob "$cron_command" "$cron_schedule" "$existing_store_pattern"
    echo "⌛️ Setting/updating cron job to backup node 'node/.config' folder every $backup_interval hours at a random minute..."
    echo
fi

# Backup existing cron jobs if selected
read -p "❔ Do you want to setup a recurring backup your existing cronjobs? (y/n): " backup_cronjobs
if [[ $backup_cronjobs =~ ^[Yy]$ ]]; then
    cron_command="crontab -l > $HOME/cron_jobs.txt && rclone $backup_type $HOME/cron_jobs.txt storj:/$bucket/$target_folder/cron_jobs.txt"
    existing_cronjobs_pattern="/cron_jobs.txt storj:"

    # Perform immediate backup
    perform_backup "$cron_command"
    echo "⌛️ Backing up your 'cronjobs' immediately..."

    # Schedule cron job
    random_minute=$(shuf -i 0-59 -n 1)
    cron_schedule="$random_minute */12 * * *"
    add_or_update_cronjob "$cron_command" "$cron_schedule" "$existing_cronjobs_pattern"
    echo "⌛️ Setting/updating cron job to backup existing cronjobs every 12 hours at a random minute..."
    echo
fi

# Backup third-party scripts folder if selected
if [ -d "$HOME/scripts/" ]; then
    read -p "❔ Do you want to setup a recurring backup your '$HOME/scripts' folder? (y/n): " backup_scripts
    if [[ $backup_scripts =~ ^[Yy]$ ]]; then
        cron_command="rclone $backup_type $HOME/scripts storj:/$bucket/$target_folder/scripts"
        existing_scripts_pattern="/scripts storj:"

        # Perform immediate backup
        perform_backup "$cron_command"
        echo "⌛️ Backing up your '$HOME/scripts' folder immediately..."

        # Schedule cron job
        random_minute=$(shuf -i 0-59 -n 1)
        cron_schedule="$random_minute */12 * * *"
        add_or_update_cronjob "$cron_command" "$cron_schedule" "$existing_scripts_pattern"
        echo "⌛️ Setting/updating cron job to backup third-party scripts folder every 12 hours at a random minute..."
        echo
    fi
fi

#====================
# FINAL ACTIONS
#====================

echo
echo "✅ Your automatic backups are all set!"
echo
echo "Here is a summary of your cronjobs:"
echo "====================================="
crontab -l
echo "====================================="
echo
echo "Your 'node.config' folder has not been backed up yet, but it will be according to the time interval you have set."
echo
# Ask user if they want to perform an immediate backup of node/.config folder
echo "❔ Do you want to perform an immediate backup of your 'node/.config' folder?"
echo "   The backup may require several minutes depending on your server bandwidth."
read -p "   Enter (y/n): " immediate_backup

if [[ $immediate_backup =~ ^[Yy]$ ]]; then
    echo "⌛️ Performing immediate backup of 'node/.config' folder..."
    if rclone $backup_type --transfers 10 --checkers 20 --disable-http2 --retries 1 --filter '+ store/**' --filter '+ store' --filter '- SELF_TEST' --filter '- keys.yml' --filter '- config.yml' /root/ceremonyclient/node/.config/ storj:/$bucket/$target_folder/.config/ --progress; then
        echo "✅ 'node/.config' backup completed successfully."
    else
        echo "❌ Error: 'node/.config' backup failed. Please check your settings/connection and try again."
        echo "   You can also manually run the backup later using the following command:"
        echo "   rclone $backup_type --transfers 10 --checkers 20 --disable-http2 --retries 1 --filter '+ store/**' --filter '+ store' --filter '- SELF_TEST' --filter '- keys.yml' --filter '- config.yml' /root/ceremonyclient/node/.config/ storj:/$bucket/$target_folder/.config/ --progress"
    fi
fi

