#!/bin/bash

# Determine the architecture and OS
ARCH=$(uname -m)
OS=$(uname -s)

BASE_URL="https://releases.quilibrium.com"

#QCLIENT_VERSION=2.0.0

# Determine qclient latest version
# Check if QCLIENT_VERSION is empty
if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
    if [ -z "$QCLIENT_VERSION" ]; then
        echo "⚠️ Warning: Unable to determine the Qclient version automatically. Continuing without it."
        echo "The script cannot proceed without a correct qclientversion number."
        echo
        echo "This could be caused by your provider blocking access to quilibrium.com"
        echo "A solution could be to change your machine DNS and try again the update script."
        echo "You can change your machine DNS with the command below:"
        echo "sudo sh -c 'echo "nameserver 8.8.8.8" | tee /etc/systemd/resolved.conf.d/dns_servers.conf > /dev/null && systemctl restart systemd-resolved'"
        echo
        echo "Or, you can try the manual step by step installation instead:"
        echo "https://docs.quilibrium.one/start/tutorials/node-step-by-step-installation"
        echo
        exit 1
    else
        echo "✅ Latest Qclient release: $QCLIENT_VERSION"
    fi
else
    echo "✅ Using specified Qclient version: $QCLIENT_VERSION"
fi

echo

# Determine the node binary name based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi


echo "QCLIENT_BINARY set to: $QCLIENT_BINARY"

# Create directories if they don't exist
mkdir -p "$HOME/ceremonyclient/client"

echo "Directories created successfully."

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
    chmod +x $QCLIENT_BINARY
    # Rename the binary to qclient, overwriting if it exists
    #mv -f "$QCLIENT_BINARY" qclient
    #chmod +x qclient
    #echo "✅ Renamed to qclient and made executable"
else
    echo "❌ Error during download: manual installation may be required."
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