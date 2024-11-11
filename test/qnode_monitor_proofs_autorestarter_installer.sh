#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Installing proof monitor script..."

# Download and install the script
if mkdir -p ~/scripts && \
   curl -sSL "https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/test/qnode_monitor_proofs_autorestarter.sh" -o ~/scripts/qnode_monitor_proofs_autorestarter.sh && \
   chmod +x ~/scripts/qnode_monitor_proofs_autorestarter.sh; then
    echo -e "${GREEN}Script downloaded and installed successfully${NC}"
else
    echo -e "${RED}Failed to download and install the script${NC}"
    exit 1
fi

# Check if cron job already exists
CRON_CMD="0 * * * * $HOME/scripts/qnode_monitor_proofs_autorestarter.sh"
if crontab -l 2>/dev/null | grep -F "$HOME/scripts/qnode_monitor_proofs_autorestarter.sh" >/dev/null; then
    echo -e "${YELLOW}Cron job already exists, skipping...${NC}"
else
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo -e "${GREEN}Added hourly cron job${NC}"
fi

echo -e "${GREEN}Installation completed:${NC}"
echo "- Script installed at: ~/scripts/qnode_monitor_proofs_autorestarter.sh"
echo "- Script will run every hour"
echo "- Logs will be stored in: ~/scripts/logs/qnode_monitor_proofs.log"