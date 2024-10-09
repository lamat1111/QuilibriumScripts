#!/bin/bash

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=1.4.19.1

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

# Determine qclient latest version
# Check if QCLIENT_VERSION is empty
if [ -z "$QCLIENT_VERSION" ]; then
    QCLIENT_VERSION=$(curl -s https://releases.quilibrium.com/qclient-release | grep -E "^qclient-[0-9]+(\.[0-9]+)*" | sed 's/^qclient-//' | cut -d '-' -f 1 |  head -n 1)
    if [ -z "$QCLIENT_VERSION" ]; then
        echo "❌ Error: Unable to determine QCLIENT_VERSION automatically."
        exit 1
    else
        echo "✅ Automatically determined QCLIENT_VERSION: $QCLIENT_VERSION"
        echo
    fi
else
    echo "✅ Using specified QCLIENT_VERSION: $QCLIENT_VERSION"
    echo
fi

# Determine the binary names based on the architecture and OS
if [ "$ARCH" = "x86_64" ]; then
    if [ "$OS" = "Linux" ]; then
        GO_BINARY="go1.22.4.linux-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go1.22.4.darwin-amd64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-amd64"
    fi
elif [ "$ARCH" = "aarch64" ]; then
    if [ "$OS" = "Linux" ]; then
        GO_BINARY="go1.22.4.linux-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-arm64"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go1.22.4.darwin-arm64.tar.gz"
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-darwin-arm64"
    fi
else
    echo "❌ Error: Unsupported system architecture ($ARCH) or operating system ($OS)."
    exit 1
fi

# Building qclient binary
if [ -n "$QCLIENT_BINARY" ]; then
    echo "⏳ Downloading qclient..."
    sleep 1  # Add a 1-second delay
    cd ~/ceremonyclient/client

    if ! wget https://releases.quilibrium.com/$QCLIENT_BINARY; then
        echo "❌ Error: Failed to download qclient binary."
        echo
    else
        echo "✅ qclient binary downloaded successfully."
        echo
        mv $QCLIENT_BINARY qclient
        echo "$QCLIENT_BINARY renamed to 'qclient'"
        chmod +x qclient
        echo
        echo "✅ qclient is ready."
        echo
    fi
else
    echo "ℹ❌ Error: Skipping qclient download as QCLIENT_BINARY could not be determined."
fi