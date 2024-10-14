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

# Function to download file and overwrite if it exists
download_and_overwrite() {
    local url="$1"
    local filename="$2"
    if wget -q -O "$filename" "$url"; then
        echo "✅ Successfully downloaded $filename"
        return 0
    else
        echo "❌ Error: Failed to download $filename"
        return 1
    fi
}

# Download the main binary
echo "Downloading $QCLIENT_BINARY..."
if download_and_overwrite "$BASE_URL/$QCLIENT_BINARY" "$QCLIENT_BINARY"; then
    # Rename the binary to qclient, overwriting if it exists
    mv -f "$QCLIENT_BINARY" qclient
    chmod +x qclient
    echo "✅ Renamed to qclient and made executable"
else
    echo "Manual installation may be required."
    exit 1
fi

# Download the .dgst file
echo "Downloading ${QCLIENT_BINARY}.dgst..."
download_and_overwrite "$BASE_URL/${QCLIENT_BINARY}.dgst" "${QCLIENT_BINARY}.dgst"

# Download signature files
echo "Downloading signature files..."
for i in {1..20}; do
    sig_file="${QCLIENT_BINARY}.dgst.sig.${i}"
    if wget -q --spider "$BASE_URL/$sig_file" 2>/dev/null; then
        download_and_overwrite "$BASE_URL/$sig_file" "$sig_file"
    fi
done

echo "Download process completed."
echo "The qclient binary is now available as 'qclient' in the current directory."