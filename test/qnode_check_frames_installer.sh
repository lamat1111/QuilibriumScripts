#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting installation of QNode frame checker...${NC}"

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

# Make script executable
if ! chmod +x ~/scripts/qnode_check_for_frames.sh; then
    echo -e "${RED}Failed to make script executable${NC}"
    exit 1
fi

# Create temporary file for crontab
TEMP_CRON=$(mktemp)
TEMP_CRON_NEW=$(mktemp)

# Export current crontab
crontab -l > "$TEMP_CRON" 2>/dev/null

# Check for existing frame checker cron entries
if grep -q "check-for-frames.sh\|qnode_check_for_frames.sh" "$TEMP_CRON"; then
    echo -e "${YELLOW}Found existing frame checker cron job(s). Removing...${NC}"
    # Keep all lines except those containing our script
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

# Clean up temporary files
rm "$TEMP_CRON" "$TEMP_CRON_NEW" 2>/dev/null

echo -e "${GREEN}Installation completed successfully!${NC}"
echo "Script location: ~/scripts/qnode_check_for_frames.sh"
echo "Cron job will run every 10 minutes"

# Show current crontab entries
echo -e "\n${YELLOW}Current crontab entries:${NC}"
crontab -l