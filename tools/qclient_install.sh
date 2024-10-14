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
    chmod +x "$QCLIENT_BINARY"
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

# Attempt to download signature files
echo "Downloading signature files..."
for i in {1..20}; do  # Adjust range as needed
    sig_file="${QCLIENT_BINARY}.dgst.sig.${i}"
    if wget -q --spider "$BASE_URL/$sig_file" 2>/dev/null; then
        if wget -q "$BASE_URL/$sig_file"; then
            echo "✅ Downloaded $sig_file"
        else
            echo "❌ Failed to download $sig_file"
        fi
    else
        break
    fi
done

echo "✅ Download process completed."