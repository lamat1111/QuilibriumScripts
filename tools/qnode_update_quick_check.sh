# Configuration
UPDATE_WAIT_TIME=1200  # 20 minutes in seconds
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/master/qnode_service_update.sh"
RELEASE_URL="https://releases.quilibrium.com/release"
NODE_DIR="/root/ceremonyclient/node"

# Function to normalize version for comparison
normalize_version() {
   echo $1 | awk -F. '{printf "%03d%03d%03d%03d", $1+0, $2+0, $3+0, $4+0}'
}

# Extract remote version
REMOTE_VERSION=$(curl -s "$RELEASE_URL" | grep -m1 "node-[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+-" | cut -d'-' -f2)

# Get local version - excluding .dgst files and handling multiple versions
LOCAL_VERSION=$(ls $NODE_DIR | grep "node-[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+-" | grep -v "\.dgst" | cut -d'-' -f2 | sort -rV | head -n1)

echo "Remote version: $REMOTE_VERSION"
echo "Local version: $LOCAL_VERSION"

if [ $(normalize_version $REMOTE_VERSION) -gt $(normalize_version $LOCAL_VERSION) ]; then
   # Check if update is already in progress
   if [ -f /tmp/node_update_in_progress ]; then
       echo "Update already in progress, skipping"
       exit 0
   fi
   
   echo "New version available. Waiting $UPDATE_WAIT_TIME seconds before updating..."
   
   # Create lock file
   touch /tmp/node_update_in_progress
   
   # Show countdown
   for i in $(seq $UPDATE_WAIT_TIME -1 1); do
       printf "\rUpdate will start in: %02d:%02d" $(($i/60)) $(($i%60))
       sleep 1
   done
   echo -e "\nStarting update..."
   
   # Execute update script
   mkdir -p ~/scripts && \
   curl -sSL "$UPDATE_SCRIPT_URL" -o ~/scripts/qnode_service_update.sh && \
   chmod +x ~/scripts/qnode_service_update.sh && \
   ~/scripts/qnode_service_update.sh
   
   # Remove lock file after update
   rm /tmp/node_update_in_progress
   exit 0
else
   echo "Current version is up to date"
   exit 0
fi