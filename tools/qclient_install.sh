#!/bin/bash

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

BASE_URL="https://releases.quilibrium.com"

# Determine the qclient binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        QCLIENT_BINARY="qclient-2.0.0-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        QCLIENT_BINARY="qclient-2.0.0-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        QCLIENT_BINARY="qclient-2.0.0-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        QCLIENT_BINARY="qclient-2.0.0-darwin-arm64"
    fi
fi

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

# Get the current OS and architecture
OS_ARCH=$(get_os_arch)

# Fetch the list of files from the release page
FILES=$(curl -s $BASE_URL | grep -oE "qclient-[0-9]+\.[0-9]+\.[0-9]+-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Change to the download directory
if ! cd ~/ceremonyclient/client; then
    echo "❌ Error: Unable to change to the download directory"
    exit 1
fi

# Download each file
download_success=true
for file in $FILES; do
    echo "Downloading $file..."
    if wget "$BASE_URL/$file"; then
        echo "Successfully downloaded $file"
    else
        echo "❌ Error: Failed to download $file"
        echo "Your node will still work, but you'll need to install the qclient manually later if needed."
        download_success=false
    fi
    echo "------------------------"
done

# Move and configure qclient binary only if all downloads were successful
if $download_success && [ -f "$QCLIENT_BINARY" ]; then
    if mv "$QCLIENT_BINARY" qclient && chmod +x qclient; then
        echo "✅ qClient binary downloaded and configured successfully."
    else
        echo "❌ Error: Failed to move or set permissions for qclient binary."
    fi
else
    echo "❌ Error: qClient binary not found or download failed. Manual installation may be required."
fi