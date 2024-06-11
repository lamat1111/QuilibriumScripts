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


==========================================================================
                    ✨ NODE "STORE" BACKUP VIA AWS ✨
==========================================================================
This script automates the backup of your node "store" data to AWS S3.
You need an AWS account and a Public/Secret access key.

For security create a user + keys specific to the bucket you want to use.

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

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
check_for_updates


# [USER INPUT]

echo "⚙️ Updating package repositories..."
sudo apt update
sleep 1

# [CHECK FOR AWS CLI]
if ! command -v aws &> /dev/null; then
    echo "⚙️ Installing AWS CLI..."
    sudo apt update
    sudo apt install awscli -y
    echo "✅ AWS CLI installed."
else
    echo "ℹ️ AWS CLI is already installed."
fi

echo "⚙️ Configuring AWS CLI..."
aws configure
sleep 1

# [USER CONFIGURATION]

echo ""
echo "ℹ️ Please specify how frequently you want to run the backup (in hours):"
read -p "Enter the backup frequency: " BACKUP_FREQUENCY
echo ""

# Prompt the user if they already have a bucket
read -p "Do you already have an AWS S3 bucket for backups? (y/n): " HAS_BUCKET
echo ""
if [[ $HAS_BUCKET == "y" ]]; then
    echo "Tip: Use a bucket specific to Quilibrium."
    read -p "Enter the name of your existing AWS S3 bucket: " BUCKET_NAME
    echo ""
else
    echo "Tip: Create a bucket specific to Quilibrium."
    read -p "Enter a name for your new AWS S3 bucket: " BUCKET_NAME
    echo ""
    # Create the bucket
    aws s3 mb s3://$BUCKET_NAME
    echo "✅ Bucket '$BUCKET_NAME' created successfully."
fi

echo ""
echo "ℹ️ Please provide a unique name for the remote folder, eg. 'Q1' (no spaces or special characters, max 20 characters)."
echo "This must be unique for each node. Your store files will be backed up inside this folder on AWS."
while true; do
    read -p "Enter the folder name: " TARGET_FOLDER
    if [[ ! "$TARGET_FOLDER" =~ ^[a-zA-Z0-9_-]{1,20}$ ]]; then
        echo "❌ Error: Folder name can only contain letters, numbers, - and _, and must be 20 characters or less."
    else
        break
    fi
done

echo ""
echo "Your remote backup location on AWS will be '$BUCKET_NAME/stores_backup/$TARGET_FOLDER/'"
echo ""
sleep 1

# [CRON JOB]

echo "⚙️ Creating cronjob to run backup every $BACKUP_FREQUENCY hours..."
RANDOM_MINUTE=$((1 + $RANDOM % 59)) # Generate a random minute between 1 and 59
CRON_EXPRESSION="$RANDOM_MINUTE */$BACKUP_FREQUENCY * * *"
(crontab -l ; echo "$CRON_EXPRESSION aws s3 sync ~/ceremonyclient/node/.config/store s3://$BUCKET_NAME/stores_backup/$TARGET_FOLDER") | crontab -
sleep 1

# [COMPLETION]

echo "✅ Backup setup complete!"
echo ""
echo "You have configured the backup to run every $BACKUP_FREQUENCY hours at minute $((1 + RANDOM % 59)) to the bucket '$BUCKET_NAME'."
sleep 1
echo ""
echo "You can test this backup with a dry run using the following command:"
echo "aws s3 sync ~/ceremonyclient/node/.config/store s3://$BUCKET_NAME//stores_backup/$TARGET_FOLDER --dryrun"
