#!/bin/bash

#Comment out for automatic creation of the qclient version
#QCLIENT_VERSION=2.0.0

# Determine the ExecStart line based on the architecture
ARCH=$(uname -m)
OS=$(uname -s)

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
        [ -n "$QCLIENT_VERSION" ] && QCLIENT_BINARY="qclient-$QCLIENT_VERSION-linux-amd64"
    elif [ "$OS" = "Darwin" ]; then
        GO_BINARY="go1.22.4.darwin-amd64.tar.gz"
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


# Get the current OS and architecture
OS_ARCH=$(get_os_arch)

# Fetch the list of files from the release page
FILES=$(curl -s $BASE_URL | grep -oE "qclient-[0-9]+\.[0-9]+\.[0-9]+-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Change to the download directory
cd ~/ceremonyclient/client

# Download each file
for file in $FILES; do
    echo "Downloading $file..."
    wget "https://releases.quilibrium.com/$file"
    
    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded $file"
    else
        echo "❌ Error: Failed to download $file"
        echo "Your node will still work, but you'll need to install the qclient manually later if needed."
    fi
    
    echo "------------------------"
done

mv $QCLIENT_BINARY qclient
chmod +x qclient
echo "✅ qClient binary downloaded and configured successfully."