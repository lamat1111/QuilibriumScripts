#!/bin/bash

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print formatted debug messages
debug_print() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Debug function for Node
debug_node() {
    debug_print $BLUE "\n=== Debugging Node Installation ==="
    
    # Check Node installation directory
    NODE_DIR="$HOME/ceremonyclient/node"
    if [ -d "$NODE_DIR" ]; then
        debug_print $GREEN "✅ Node directory found: $NODE_DIR"
    else
        debug_print $RED "❌ Node directory not found at $NODE_DIR"
        debug_print $YELLOW "Suggestion: Ensure you've installed the Node correctly. Run the installation script if needed."
        return
    fi

    # Find Node binary
    NODE_BINARY=$(find "$NODE_DIR" -name "node-*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$NODE_BINARY" ]; then
        debug_print $GREEN "✅ Node binary found: $NODE_BINARY"
        CURRENT_NODE_VERSION=$(basename "$NODE_BINARY" | grep -oP 'node-\K[0-9]+(\.[0-9]+){2,3}')
        debug_print $GREEN "Current Node version: $CURRENT_NODE_VERSION"
    else
        debug_print $RED "❌ No executable Node binary found in $NODE_DIR"
        debug_print $YELLOW "Suggestion: Check if the Node was installed correctly. You might need to reinstall."
        return
    fi

    # Check latest Node version
    LATEST_NODE_VERSION=$(curl -s https://releases.quilibrium.com/release | grep -oP 'node-\K[0-9]+(\.[0-9]+){2,3}' | sort -V | tail -n 1)
    if [ -n "$LATEST_NODE_VERSION" ]; then
        debug_print $GREEN "Latest Node version from server: $LATEST_NODE_VERSION"
    else
        debug_print $RED "❌ Failed to fetch latest Node version from server"
        debug_print $YELLOW "Suggestion: Check your internet connection or try again later."
        return
    fi

    # Compare versions
    if version_gt "$LATEST_NODE_VERSION" "$CURRENT_NODE_VERSION"; then
        debug_print $YELLOW "⚠️ Node update is needed"
    else
        debug_print $GREEN "✅ Node is up to date"
    fi
}

# Debug function for Qclient
debug_qclient() {
    debug_print $BLUE "\n=== Debugging Qclient Installation ==="
    
    # Check Qclient installation directory
    CLIENT_DIR="$HOME/ceremonyclient/client"
    if [ -d "$CLIENT_DIR" ]; then
        debug_print $GREEN "✅ Qclient directory found: $CLIENT_DIR"
    else
        debug_print $RED "❌ Qclient directory not found at $CLIENT_DIR"
        debug_print $YELLOW "Suggestion: Ensure you've installed the Qclient correctly. Run the installation script if needed."
        return
    fi

    # Find Qclient binary
    QCLIENT_BINARY=$(find "$CLIENT_DIR" -name "qclient-*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$QCLIENT_BINARY" ]; then
        debug_print $GREEN "✅ Qclient binary found: $QCLIENT_BINARY"
        CURRENT_QCLIENT_VERSION=$(basename "$QCLIENT_BINARY" | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){2,3}')
        debug_print $GREEN "Current Qclient version: $CURRENT_QCLIENT_VERSION"
    else
        debug_print $RED "❌ No executable Qclient binary found in $CLIENT_DIR"
        debug_print $YELLOW "Suggestion: Check if the Qclient was installed correctly. You might need to reinstall."
        return
    fi

    # Check latest Qclient version
    LATEST_QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -oP 'qclient-\K[0-9]+(\.[0-9]+){2,3}' | sort -V | tail -n 1)
    if [ -n "$LATEST_QCLIENT_VERSION" ]; then
        debug_print $GREEN "Latest Qclient version from server: $LATEST_QCLIENT_VERSION"
    else
        debug_print $RED "❌ Failed to fetch latest Qclient version from server"
        debug_print $YELLOW "Suggestion: Check your internet connection or try again later."
        return
    fi

    # Compare versions
    if version_gt "$LATEST_QCLIENT_VERSION" "$CURRENT_QCLIENT_VERSION"; then
        debug_print $YELLOW "⚠️ Qclient update is needed"
    else
        debug_print $GREEN "✅ Qclient is up to date"
    fi
}

# Main execution
echo "Starting Q1 Debug Script..."
debug_node
debug_qclient
echo -e "\nDebug process completed. If you're still experiencing issues, please share this output with the support team."