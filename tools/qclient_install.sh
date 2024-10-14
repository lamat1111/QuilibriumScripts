#!/bin/bash

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
if wget -q "$BASE_URL/$QCLIENT_BINARY"; then
    echo "✅ Successfully downloaded $QCLIENT_BINARY"
    # Rename the binary to qclient, overwriting if it exists
    mv -f "$QCLIENT_BINARY" qclient
    chmod +x qclient
    echo "✅ Renamed to qclient and made executable"
else
    echo "❌ Error: Failed to download $QCLIENT_BINARY"
    echo "Manual installation may be required."
    exit 1
fi

# Download the .dgst file
echo "Downloading ${QCLIENT_BINARY}.dgst..."
if wget -q "$BASE_URL/${QCLIENT_BINARY}.dgst"; then
    echo "✅ Successfully downloaded ${QCLIENT_BINARY}.dgst"
else
    echo "❌ Error: Failed to download ${QCLIENT_BINARY}.dgst"
fi

# Fetch and download all signature files
echo "Downloading signature files..."
sig_files=$(curl -s "$BASE_URL" | grep -oP "${QCLIENT_BINARY}\.dgst\.sig\.\K[0-9]+")
for sig_num in $sig_files; do
    sig_file="${QCLIENT_BINARY}.dgst.sig.${sig_num}"
    if wget -q "$BASE_URL/$sig_file"; then
        echo "✅ Downloaded $sig_file"
    else
        echo "❌ Failed to download $sig_file"
    fi
done

echo "✅ Download process completed."
echo "The qclient binary is now available as 'qclient' in the current directory."