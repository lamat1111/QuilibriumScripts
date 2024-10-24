#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo privileges to install required packages${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting installation of QNode frame checker...${NC}"
echo
sleep 1

# Function to install required packages
install_dependencies() {
    local packages=("jq" "bc" "cron")    # Added cron to the array
    local missing_packages=()

    # Check which packages need to be installed
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done

    # If there are missing packages, install them
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing required packages: ${missing_packages[*]}${NC}"
        apt-get update -qq
        if ! apt-get install -y "${missing_packages[@]}"; then
            echo -e "${RED}Failed to install required packages${NC}"
            return 1
        fi
        echo -e "${GREEN}Successfully installed required packages${NC}"
    else
        echo -e "${GREEN}All required packages are already installed${NC}"
    fi
    return 0
}

# Install dependencies
if ! install_dependencies; then
    exit 1
fi

# Create scripts directory
if ! mkdir -p ~/scripts; then
    echo -e "${RED}Failed to create scripts directory${NC}"
    exit 1
fi

# Download the script
echo "Downloading qnode_check_for_frames.sh..."
if ! curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/qnode_check_for_frames.sh" -o ~/scripts/qnode_check_for_frames.sh; then
    echo -e "${RED}Failed to download the script${NC}"
    exit 1
fi
echo -e "${GREEN}Download completed successfully${NC}"
echo
sleep 1

# Make script executable
if ! chmod +x ~/scripts/qnode_check_for_frames.sh; then
    echo -e "${RED}Failed to make script executable${NC}"
    exit 1
fi
echo -e "${GREEN}Script permissions set successfully${NC}"
echo
sleep 1

# Set up cron job
TEMP_CRON=$(mktemp)
TEMP_CRON_NEW=$(mktemp)

# Export current crontab
crontab -l > "$TEMP_CRON" 2>/dev/null

# Check for existing frame checker cron entries
if grep -q "check-for-frames.sh\|qnode_check_for_frames.sh" "$TEMP_CRON"; then
    echo -e "${YELLOW}Found existing frame checker cron job(s). Removing...${NC}"
    grep -v "check-for-frames.sh\|qnode_check_for_frames.sh" "$TEMP_CRON" > "$TEMP_CRON_NEW"
    mv "$TEMP_CRON_NEW" "$TEMP_CRON"
    echo -e "${GREEN}Old cron jobs removed successfully${NC}"
fi

# Add new cron job
echo "*/10 * * * * ${HOME}/scripts/qnode_check_for_frames.sh" >> "$TEMP_CRON"

# Install new crontab
if ! crontab "$TEMP_CRON"; then
    echo -e "${RED}Failed to install cron job${NC}"
    rm "$TEMP_CRON" "$TEMP_CRON_NEW" 2>/dev/null
    exit 1
fi
echo -e "${GREEN}Cron job installed successfully${NC}"

# Clean up temporary files
rm "$TEMP_CRON" "$TEMP_CRON_NEW" 2>/dev/null

# Check and remove old script if it exists
if [ -f "$HOME/check-for-frames.sh" ]; then
    echo -e "${YELLOW}Found old script at $HOME/check-for-frames.sh${NC}"
    if rm "$HOME/check-for-frames.sh"; then
        echo -e "${GREEN}Successfully removed old script${NC}"
        echo
        sleep 1
    else
        echo -e "${RED}Failed to remove old script${NC}"
        echo
        sleep 1
    fi
fi

echo -e "${GREEN}Installation completed successfully!${NC}"
echo "Script location: ~/scripts/qnode_check_for_frames.sh"
echo "Cron job will run every 10 minutes"
echo
sleep 1

echo -e "${YELLOW}Current crontab entries:${NC}"
crontab -l
echo