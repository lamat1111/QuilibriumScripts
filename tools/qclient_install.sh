#!/bin/bash

set -e

# Set BASE_URL
BASE_URL="https://releases.quilibrium.com"

# Determine the OS and architecture
get_os_arch() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $arch in
        x86_64)
            arch="amd64"
            ;;
        aarch64)
            arch="arm64"
            ;;
    esac
    
    echo "${os}-${arch}"
}

OS_ARCH=$(get_os_arch)

# Determine qclient latest version
if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(curl -s "$BASE_URL/qclient-release" | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 | head -n 1)
    if [ -z "$QCLIENT_VERSION" ]; then
        echo "❌ Error: Unable to determine QCLIENT_VERSION automatically."
        exit 1
    else
        echo "✅ Automatically determined QCLIENT_VERSION: $QCLIENT_VERSION"
    fi
else
    echo "✅ Using specified QCLIENT_VERSION: $QCLIENT_VERSION"
fi

# Set the QCLIENT_BINARY based on OS_ARCH
QCLIENT_BINARY="qclient-$QCLIENT_VERSION-$OS_ARCH"

# Fetch the list of files from the release page
FILES=$(curl -s "$BASE_URL" | grep -oE "qclient-$QCLIENT_VERSION-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Create and change to the download directory
mkdir -p ~/ceremonyclient/client
cd ~/ceremonyclient/client

# Download each file
for file in $FILES; do
    echo "Downloading $file..."
    wget -O "$file" "$BASE_URL/$file"
    
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded $file"
    else
        echo "❌ Error: Failed to download $file"
        echo "Your node will still work, but you'll need to install the qclient manually later if needed."
    fi
    
    echo "------------------------"
done

if [ -f "$QCLIENT_BINARY" ]; then
    mv -f "$QCLIENT_BINARY" qclient
    chmod +x qclient
    echo "✅ qClient binary downloaded and configured successfully."
else
    echo "❌ Error: qClient binary not found. Please check the download process."
    ls -la  # List directory contents for debugging
fi

# Clean up old files
echo "Cleaning up old files..."
find . -type f -name "qclient-*" ! -name "$QCLIENT_BINARY" -delete
echo "✅ Cleanup completed."

# Print debug information
echo "Debug Information:"
echo "OS_ARCH: $OS_ARCH"
echo "QCLIENT_VERSION: $QCLIENT_VERSION"
echo "QCLIENT_BINARY: $QCLIENT_BINARY"
echo "FILES: $FILES"