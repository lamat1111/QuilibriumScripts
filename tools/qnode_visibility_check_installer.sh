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
                              
============================================================================
                  ✨ QNODE VISIBILITY CHECK INSTALLER ✨
============================================================================
This script will install the "Visibility Check" script and set up
a cronjob to run it every hour at a random minute.

The "Visibility Check" script will check the visibility of your node,
and if it's not visible to Bootstrap Peers, it will restart it.

Follow the Quilibrium Node guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
============================================================================

Processing... ⏳

EOF

sleep 5  # Add a 7-second delay

# Get the home directory of the current user
HOME=$(eval echo ~$USER)

# Step 1: Create $HOME/scripts directory if it doesn't exist
if [ ! -d "$HOME/scripts" ]; then
    mkdir -p "$HOME/scripts"
    echo "✅ Created $HOME/scripts directory."
fi

# Step 2: Download the script from GitHub
script_url="https://github.com/lamat1111/QuilibriumScripts/raw/main/tools/qnode_visibility_check_autorestart.sh"
script_path="$HOME/scripts/qnode_visibility_check_autorestart.sh"

curl -L $script_url -o $script_path
if [ $? -eq 0 ]; then
    echo "✅ Downloaded qnode_visibility_check_autorestart.sh to $HOME/scripts."
else
    echo "❌ Failed to download qnode_visibility_check_autorestart.sh."
    exit 1
fi

# Make the script executable
chmod +x $script_path

# Step 3: Set up a cron job to run the script every hour at a random minute
cron_minute=$((RANDOM % 60))
cron_command="$cron_minute * * * * /bin/bash $script_path"

# Add the cron job
(crontab -l 2>/dev/null; echo "$cron_command") | crontab -

echo "✅ Cron job added to run the script automatically"
echo ""
echo "The 'Visibility Check' script will now check the visibility of your node,"
echo "every hour at minute $cron_minute, and if it's not visible to Bootstrap Peers, it will restart it."
