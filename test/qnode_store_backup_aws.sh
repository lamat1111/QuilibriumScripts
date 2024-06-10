#!/bin/bash

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


===================================================================
                  ✨ STORE BACKUP VIA AWS ✨
===================================================================
This script automates the backup of your data to AWS S3.
You need an AWS account and a Public/Secret access key.
For security creates a user + keys specific to the bucket you want to use.

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

Processing... ⏳

EOF

sleep 7 # add sleep time

# Function to check for newer script version and update
check_for_updates() {
    SCRIPT_CHECKSUM=$(md5sum ~/scripts/qnode_store_backup_aws.sh | awk '{ print $1 }')
    LATEST_CHECKSUM=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_store_backup_aws.sh | md5sum | awk '{ print $1 }')

    if [ "$SCRIPT_CHECKSUM" != "$LATEST_CHECKSUM" ]; then
        echo "Updating the script to the latest version..."
        sleep 1
        curl -o ~/scripts/qnode_store_backup_idrive.sh https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_store_backup_aws.sh || display_error "❌ Failed to download the newer version of the script."
        chmod +x ~/scripts/qnode_store_backup_aws.sh || display_error "❌ Failed to set execute permission for the updated script."
        echo "✅ Script updated successfully."
        sleep 1
        echo "Please run the script again."
        exit 0
    fi
}

# Check for updates and update if available
#check_for_updates


# [USER INPUT]

echo "⚙️ Updating package repositories..."
sudo apt update
sleep 1

echo "⚙️ Installing AWS CLI..."
sudo apt install awscli
sleep 1

echo "⚙️ Configuring AWS CLI..."
aws configure
sleep 1

# [USER CONFIGURATION]

echo "ℹ️ Please specify how frequently you want to run the backup (in hours):"
read -p "Enter the backup frequency: " BACKUP_FREQUENCY

echo "ℹ️ Please provide the name of your AWS S3 bucket:"
read -p "Enter bucket name: " BUCKET_NAME

echo "ℹ️ Please provide a unique name for the remote folder (no spaces or special characters, max 20 characters):"
while true; do
    read -p "Enter the folder name: " TARGET_FOLDER
    if [[ ! "$TARGET_FOLDER" =~ ^[a-zA-Z0-9_-]{1,20}$ ]]; then
        echo "❌ Error: Folder name can only contain letters, numbers, - and _, and must be 20 characters or less."
    else
        break
    fi
done

# [CRON JOB]

echo "⚙️ Creating cronjob to run backup every $BACKUP_FREQUENCY hours..."
sleep 1
CRON_EXPRESSION="0 */$BACKUP_FREQUENCY * * *"
(crontab -l ; echo "$CRON_EXPRESSION aws s3 sync ~/ceremonyclient/node/.config/store s3://$BUCKET_NAME/$TARGET_FOLDER") | crontab -
sleep 1

# [COMPLETION]

echo "✅ Backup setup complete!"
echo ""
echo "You have configured the backup to run every $BACKUP_FREQUENCY hours to the bucket '$BUCKET_NAME'."
sleep 1
echo ""
echo "You can test this backup with a dry run using the following command:"
echo "aws s3 sync ~/ceremonyclient/node/.config/store s3://$BUCKET_NAME/$TARGET_FOLDER --dryrun"
