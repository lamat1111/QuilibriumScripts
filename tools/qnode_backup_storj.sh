# [SCRIPT HEADER]

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
#check_for_updates

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

# Prompt the user for StorJ S3 credentials
echo
echo "Your SECRET key won't be showed. Just right click to paste and press ENTER"
echo
read -p "🔒 Enter your StorJ access key: " access_key
read -sp "🔒 Enter your StorJ SECRET key: " secret_key
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
    echo "▶️ Create a new StorJ bucket using lowercase characters [a-z][0-9][-.]"
    while true; do
        read -p "Enter your StorJ bucket name: " bucket
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
read -p "▶️ Enter the target folder name, e.g., 'quil-1': " target_folder
echo

# Prompt for the backup choice
echo "❔ What kind of backup do you want to create?"
echo "If you chose to backup your keys, these will be always be copied and not synced for security."
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

# Install rclone silently
echo "⌛️ Installing rclone..."
sudo -v
curl -s https://rclone.org/install.sh | sudo bash > /dev/null
echo "rclone installed successfully."
echo

# Ensure rclone config directory exists
mkdir -p $HOME/.config/rclone

# Remove existing StorJ bucket configuration
sed -i '/^\[storj\]/,/^$/d' "$HOME/.config/rclone/rclone.conf"

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
read -p "❔ Do you want to backup your node 'keys.yml' and 'config.yml' files? (y/n): " backup_keys
if [[ $backup_keys =~ ^[Yy]$ ]]; then
    echo "⌛️ Copying node 'keys.yml' and 'config.yml' files... (I will back up these only once)."
    rclone copy $HOME/ceremonyclient/node/.config/keys.yml storj:/$bucket/$target_folder/keys/
    rclone copy $HOME/ceremonyclient/node/.config/config.yml storj:/$bucket/$target_folder/keys/
    echo "✅ Your keys are now backed up in 'storj:/$bucket/$target_folder/keys'"
    echo
fi


# Function to check if a cron job with a specific pattern exists
cron_job_exists() {
    local pattern="$1"
    crontab -l | grep -q "$pattern"
}

# Function to add new cronjobs
add_new_cronjob() {
    local cron_command="$1"
    local cron_schedule="$2"
    echo "$cron_schedule $cron_command" | crontab -
}

#!/bin/bash

# Backup node store folder if selected
read -p "❔ Do you want to backup your node 'store' folder? (y/n): " backup_node_folder
if [[ $backup_node_folder =~ ^[Yy]$ ]]; then
    read -p "▶️ How frequently do you want to backup your 'store' folder (in hours): " backup_interval
    random_minute=$(shuf -i 0-59 -n 1)
    cron_schedule="$random_minute */$backup_interval * * *"
    echo
    cron_command="rclone $backup_type --transfers 10 --checkers 20 --disable-http2 --retries 1 $HOME/ceremonyclient/node/.config/store storj:/$bucket/$target_folder/store"
    existing_store_pattern="/ceremonyclient/node/.config/store storj:"
    if ! crontab -l | grep -q "$existing_store_pattern"; then
        (crontab -l ; echo "$cron_schedule $cron_command") | crontab -
        echo "⌛️ Setting cron job to backup node 'store' folder every $backup_interval hours at a random minute..."
    else
        echo "⚠️ Cron job to backup node 'store' folder already exists. Skipping..."
        echo
    fi
fi

# Backup existing cronjobs if selected
read -p "❔ Do you want to backup your existing cronjobs? (y/n): " backup_cronjobs
if [[ $backup_cronjobs =~ ^[Yy]$ ]]; then
    random_minute=$(shuf -i 0-59 -n 1)
    cron_schedule="$random_minute */12 * * *"
    cron_command="crontab -l > $HOME/cron_jobs.txt && rclone $backup_type $HOME/cron_jobs.txt storj:/$bucket/$target_folder/cron_jobs.txt"
    existing_cronjobs_pattern="/cron_jobs.txt storj:"
    if ! crontab -l | grep -q "$existing_cronjobs_pattern"; then
        (crontab -l ; echo "$cron_schedule $cron_command") | crontab -
        echo "⌛️ Setting cron job to backup existing cronjobs every 12 hours at a random minute..."
    else
        echo "⚠️ Cron job to backup existing cron jobs already exists. Skipping..."
        echo
    fi
fi

# Backup third-party scripts folder if selected
if [ -d "$HOME/scripts/" ]; then
    read -p "❔ Do you want to backup your third-party scripts folder? (y/n): " backup_scripts
    if [[ $backup_scripts =~ ^[Yy]$ ]]; then
        echo
        random_minute=$(shuf -i 0-59 -n 1)
        cron_schedule="$random_minute */12 * * *"
        cron_command="rclone $backup_type $HOME/scripts storj:/$bucket/$target_folder/scripts"
        existing_scripts_pattern="/scripts storj:"
        if ! crontab -l | grep -q "$existing_scripts_pattern"; then
            (crontab -l ; echo "$cron_schedule $cron_command") | crontab -
            echo "⌛️ Setting cron job to backup third-party scripts folder every 12 hours at a random minute..."
        else
            echo "⚠️ Cron job to backup third-party scripts folder already exists. Skipping..."
            echo
        fi
    fi
fi

# Done
  echo "✅ Your automatic backups are all set!"
  echo
  echo "Here is a summary of your cronjobs:"
  echo
  crontab -l
