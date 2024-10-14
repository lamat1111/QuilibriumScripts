#!/bin/bash

set -x  # Enable debug mode

# Determine the architecture and OS
ARCH=$(uname -m)
OS=$(uname -s)

BASE_URL="https://releases.quilibrium.com"

# Determine the qclient binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        QCLIENT_BINARY="qclient-2.0.0-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        QCLIENT_BINARY="qclient-2.0.0-darwin-arm64"  # Note: There's no darwin-amd64 in the list
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        QCLIENT_BINARY="qclient-2.0.0-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        QCLIENT_BINARY="qclient-2.0.0-darwin-arm64"
    fi
fi

echo "QCLIENT_BINARY set to: $QCLIENT_BINARY"

# Change to the download directory
if ! cd ~/ceremonyclient/client; then
    echo "❌ Error: Unable to change to the download directory"
    exit 1
fi

# Download the main binary
echo "Downloading $QCLIENT_BINARY..."
if wget "$BASE_URL/$QCLIENT_BINARY"; then
    echo "✅ Successfully downloaded $QCLIENT_BINARY"
    chmod +x "$QCLIENT_BINARY"
    echo "✅ Made $QCLIENT_BINARY executable"
else
    echo "❌ Error: Failed to download $QCLIENT_BINARY"
    echo "Manual installation may be required."
    exit 1
fi

# Download the .dgst file
echo "Downloading ${QCLIENT_BINARY}.dgst..."
if wget "$BASE_URL/${QCLIENT_BINARY}.dgst"; then
    echo "✅ Successfully downloaded ${QCLIENT_BINARY}.dgst"
else
    echo "❌ Error: Failed to download ${QCLIENT_BINARY}.dgst"
fi

# Get the list of all files for the current binary
echo "Fetching list of signature files..."
ALL_FILES=$(curl -s $BASE_URL | grep -oE "${QCLIENT_BINARY}\.dgst\.sig\.[0-9]+")

# Download all signature files
for sig_file in $ALL_FILES; do
    echo "Downloading $sig_file..."
    if wget "$BASE_URL/$sig_file"; then
        echo "✅ Successfully downloaded $sig_file"
    else
        echo "❌ Error: Failed to download $sig_file"
    fi
done

echo "Download process completed."
ls -l

set +x  # Disable debug mode