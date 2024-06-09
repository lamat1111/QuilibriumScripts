#!/bin/bash

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
  echo "ℹ️ Enter the desired backup interval in hours (e.g., 1, 3, 24):"
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
echo "⚙️ Log in to your IDrive account..."
sleep 1
$IDRIVE_BIN_PATH/idrive -i

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
else
  echo "❌ Failed to log in to IDrive."
fi
