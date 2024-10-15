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
                ✨ QNODE CPUQUOTA REMOVER ✨
===================================================================
This script will remove the CPUQuota limit from your 
node service file.

Made with 🔥 by LaMat - https://quilibrium.one
====================================================================

Processing... ⏳

EOF

sleep 7  # Add a 7-second delay

#variables
HOME=$(eval echo ~$USER)
NODE_PATH="$HOME/ceremonyclient/node"
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"

# Stop the ceremonyclient service
echo "🛑 Stopping Ceremonyclient Service"
service ceremonyclient stop
sleep 5

# Find and comment out the CPUQuota line in the service file
if grep -q "^CPUQuota=" "$SERVICE_FILE"; then
    sed -i 's/^CPUQuota=.*$/# &/' "$SERVICE_FILE"
    echo "✅ CPUQuota line commented out in $SERVICE_FILE"
else
    echo "ℹ️ No CPUQuota line found in $SERVICE_FILE"
fi


# Remove the SELF_TEST file
if [ -f "$NODE_PATH/.config/SELF_TEST" ]; then
    echo "🗑️ Removing SELF_TEST file..."
    if rm "$NODE_PATH/.config/SELF_TEST"; then
        echo "✅ SELF_TEST file removed successfully."
    else
        echo "❌ Error: Failed to remove SELF_TEST file." >&2
        exit 1
    fi
else
    echo "ℹ️ No SELF_TEST file found at $NODE_PATH/.config/SELF_TEST."
fi
sleep 1  # Add a 1-second delay


# Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start
echo "✅ All done!"
echo "Here is your service file"
echo =""
# Display the service file
cat "$SERVICE_FILE"
