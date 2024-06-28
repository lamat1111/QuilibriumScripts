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


===================================================================
             ✨ OOM Monitoring Script Installer ✨
===================================================================
This script will:
1. Create a monitoring script to check RAM usage
2. Set up a cron job to run the monitoring script every 10 minutes
3. The monitoring script will restart the ceremonyclient service 
if RAM usage exceeds 97%

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

Processing... ⏳

EOF

sleep 5 # add sleep time

# Check if ceremonyclient.service exists
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "❌ Error: The file $SERVICE_FILE does not exist. Ceremonyclient service setup failed."
    exit 1
fi

# Define variables
SCRIPT_DIR=~/scripts
SCRIPT_FILE=$SCRIPT_DIR/qnode_oom_sys_restart.sh

# Function to check if a command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        echo "❌ Error: $1"
        sleep 1
        exit 1
    fi
}

# Create the scripts directory if it doesn't exist
echo "⌛️ Creating script directory..."
sleep 1
mkdir -p $SCRIPT_DIR
check_command "Failed to create script directory"

# Overwrite the monitoring script if it already exists
echo "⌛️ Creating or overwriting monitoring script..."
sleep 1
cat << 'EOF' >| $SCRIPT_FILE
#!/bin/bash

LOG_DIR=~/scripts/log
mkdir -p $LOG_DIR

# Function to get the current RAM usage percentage
get_ram_usage() {
    free | awk '/Mem/{printf("%.2f\n"), $3/$2*100}'
}

# Function to restart the ceremonyclient service
restart_service() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp: RAM usage is above 98%. Restarting ceremonyclient service..." | tee -a $LOG_DIR/monitor.log
    if sudo service ceremonyclient restart; then
        echo "$timestamp: ceremonyclient service restarted successfully." >> $LOG_DIR/qnode_oom_sys_restart.log
    else
        echo "$timestamp: Failed to restart ceremonyclient service." >> $LOG_DIR/qnode_oom_sys_restart.log
    fi
}

# Check RAM usage and restart service if necessary
RAM_USAGE=$(get_ram_usage)
if (( $(echo "$RAM_USAGE > 98.00" | bc -l) )); then
    restart_service
fi
EOF
check_command "Failed to create or overwrite monitoring script"

# Make the script executable
echo "⌛️ Making the script executable..."
sleep 1
chmod +x $SCRIPT_FILE
check_command "Failed to make script executable"

# Check if cron job already exists
echo "⌛️ Checking if cron job exists..."
sleep 1
if crontab -l | grep -q "$SCRIPT_FILE"; then
    echo "✅ Cron job already exists. Skipping..."
else
    # Create a cron job to run the script every 10 minutes
    echo "⌛️ Setting up cron job..."
    sleep 1
    if (crontab -l 2>/dev/null; echo "*/10 * * * * $SCRIPT_FILE") | crontab -; then
        echo "✅ Cron job created successfully."
        sleep 1
    else
        echo "❌ Failed to create cron job. Please check your permissions."
        sleep 1
        exit 1
    fi
fi

echo "✅ Installation complete. The monitoring script has been set up and the cron job has been created or skipped."
sleep 1
echo "You can find the monitoring script at: $SCRIPT_FILE"
sleep 1
echo "Logs will be written to: ~/scripts/log/"
sleep 1
