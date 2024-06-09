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
    

=============================================================================
                   ✨ QNODE STORE BACKUP on IDRIVE ✨
=============================================================================
This script will setup an automatic backup of your store folder to IDrive.
You need an 'IDrive Business' account for this to work.
Cost: $69 per year for 250 GB of space and unlimited servers.

⭐️ Signup for IDrive here: https://quilibrium.one/idrive

Made with 🔥 by LaMat - https://quilibrium.one
=============================================================================
Processing... ⏳

EOF

sleep 7  # Add a 7-second delay

# Function to check for newer script version and update
check_for_updates() {
    SCRIPT_CHECKSUM=$(md5sum ~/scripts/qnode_store_backup_idrive.sh | awk '{ print $1 }')
    LATEST_CHECKSUM=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_store_backup_idrive.sh | md5sum | awk '{ print $1 }')

    if [ "$SCRIPT_CHECKSUM" != "$LATEST_CHECKSUM" ]; then
        echo "Updating the script to the latest version..."
        sleep 1
        curl -o ~/scripts/qnode_store_backup_idrive.sh https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/tools/qnode_store_backup_idrive.sh || display_error "❌ Failed to download the newer version of the script."
        chmod +x ~/scripts/qnode_store_backup_idrive.sh || display_error "❌ Failed to set execute permission for the updated script."
        echo "✅ Script updated successfully."
        sleep 1
        echo "Please run the script again."
        exit 0
    fi
}

# Check for updates and update if available
#check_for_updates

# ==================
# Checking if iDrive is Downloaded and Installed
# ==================

# Function to display error messages and exit
display_error_idrive() {
    echo "❌ Error: $1"
    echo "Try again from the beginning by running:"
    echo "~/scripts/qnode_store_backup_idrive.sh"
    exit 1
}

# Function to display error messages and exit
display_error_idrive() {
    echo "❌ Error: $1"
    echo "Try again from the beginning by running:"
    echo "~/scripts/qnode_store_backup_idrive.sh"
    exit 1
}

# Check if iDrive is installed
if ! command -v idrive >/dev/null 2>&1; then
    # Check if idriveforlinux.bin is downloaded
    if [ ! -f idriveforlinux.bin ]; then
        # Prompt user to download and install iDrive
        echo "⚠️ iDrive is not installed."
        echo "Do you want to download and install iDrive for Linux now? (y/n)"
        read -r CHOICE
        if [ "$CHOICE" = "y" ]; then
            # Download iDrive for Linux
            echo "Downloading iDrive for Linux..."
            wget https://www.idrivedownloads.com/downloads/linux/download-for-linux/linux-bin/idriveforlinux.bin || display_error_idrive "Failed to download iDrive for Linux."
            chmod +x idriveforlinux.bin || display_error "Failed to set execute permission for iDrive for Linux."
            echo "✅ iDrive for Linux downloaded successfully."
            sleep 1
            echo ""
            
            # Install iDrive for Linux
            echo "Installing iDrive for Linux..."
            INSTALL_OUTPUT=$(./idriveforlinux.bin --install 2>&1)
            if echo "$INSTALL_OUTPUT" | grep -q "Failed to complete installation. Please reinstall IDrive package."; then
                display_error_idrive "Failed to install iDrive for Linux. Please reinstall IDrive package."
            fi
            echo "✅ iDrive for Linux installed successfully."
            sleep 1
            echo ""
        else
            echo "Installation of iDrive for Linux cancelled."
            exit 1
        fi
    else
        # Install iDrive for Linux directly
        echo "⚠️ iDrive for Linux is downloaded but not installed."
        echo "Installing iDrive for Linux..."
        INSTALL_OUTPUT=$(./idriveforlinux.bin --install 2>&1)
        if echo "$INSTALL_OUTPUT" | grep -q "Failed to complete installation. Please reinstall IDrive package."; then
            display_error_idrive "Failed to install iDrive for Linux. Please reinstall IDrive package."
        fi
        echo "✅ iDrive for Linux installed successfully."
        sleep 1
        echo ""
    fi
else
    # iDrive is installed
    echo "✅ iDrive for Linux is installed."
    echo ""
fi



# Variables
IDRIVE_BIN_PATH="/opt/IDriveForLinux/bin/idrive"
SOURCE_PATH="$HOME/ceremonyclient/node/.config/store"

# Function to validate target folder name
validate_target_folder() {
  # Check if the input contains spaces or special characters
  if [[ "$1" =~ [^a-zA-Z0-9_-] || "$1" =~ [[:space:]] ]]; then
    echo "❌ Error: Target folder name must contain only letters, numbers, underscores, dashes."
    echo "It should not contain spaces or special characters."
    echo ""
    return 1
  fi
}

# ==================
# Function to schedule backup job
# ==================
schedule_backup() {
  echo "⚙️ Scheduling backup job..."
  sleep 1

  # Check if a cron job already exists for the given source path
  if crontab -l | grep -q "$SOURCE_PATH"; then
    echo "⚠️ A backup job is already scheduled for $SOURCE_PATH. Do you want to overwrite it? (y/n)"
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
      echo "⚠️ Backup job scheduling cancelled."
      return
    fi
  fi

  # Prompt user for backup interval in hours
  echo "ℹ️ Enter the desired backup interval in hours (e.g., 1, 2, 3... 24):"
  read -r BACKUP_INTERVAL

  # Validate input and set the cron expression
  if [[ "$BACKUP_INTERVAL" =~ ^[0-9]+$ ]]; then
    RANDOM_MINUTE=$((RANDOM % 60))
    CRON_EXPRESSION="$RANDOM_MINUTE */$BACKUP_INTERVAL * * * $IDRIVE_BIN_PATH/idrive -b --src $SOURCE_PATH --dst $TARGET_BASE_PATH"
    echo "⚙️ The backup job is scheduled to run at minute $RANDOM_MINUTE every $BACKUP_INTERVAL hours."
  else
    echo "⚠️ Invalid input for backup interval. Using 1 hour as default."
    RANDOM_MINUTE=$((RANDOM % 60))
    CRON_EXPRESSION="$RANDOM_MINUTE * * * * $IDRIVE_BIN_PATH/idrive -b --src $SOURCE_PATH --dst $TARGET_BASE_PATH"
    echo "⚙️ The backup job is scheduled to run at minute $RANDOM_MINUTE every hour."
  fi

  (crontab -l 2>/dev/null; echo "$CRON_EXPRESSION") | crontab -
  if [ $? -eq 0 ]; then
    echo "✅ Backup job scheduled successfully."
  else
    echo "❌ Failed to schedule backup job."
  fi
}

# ==================
# Main script execution
# ==================
#echo "⚙️ Log in to your IDrive account..."
#sleep 1
#$IDRIVE_BIN_PATH/idrive -i

if [ $? -eq 0 ]; then
  # Prompt user for target folder name and validate
  while true; do
    echo "ℹ️ Enter the name you want to give to the target folder on IDrive (e.g., 'Q1')."
    echo "Must be different for each server/node you back up! No spaces or special characters."
    read -r TARGET_FOLDER
    if validate_target_folder "$TARGET_FOLDER"; then
      break
    fi
  done

  TARGET_BASE_PATH="$HOME/Quilibrium/$TARGET_FOLDER/store"
  echo "ℹ️ Your iDrive path for this backup will be '$TARGET_BASE_PATH'"
  echo ""
  sleep 1

  schedule_backup
  echo "✅ Setup complete to back up $SOURCE_PATH"
  sleep 1
  echo ""
  echo "Your store folder will be backed up every $BACKUP_INTERVAL hours automatically."
  sleep 1
  echo "Each backup is incremental, so only the new files will be backed up."
  echo "If you delete the store folder from your server, the backup on iDrive will remaion intact."
  sleep 1
  echo ""
  echo "If you want to test the backup right now, you can run the below command."
  echo "If you do, you will have to be patient because the first backup may take time."
  echo "Test command:"
  echo "$IDRIVE_BIN_PATH/idrive -b --src $SOURCE_PATH --dst $TARGET_BASE_PATH"
else
  display_error_idrive "❌ Failed to complete back up process."
fi
