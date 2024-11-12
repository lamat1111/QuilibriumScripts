#!/bin/bash

#==========================
# NODE BINARY DOWNLOAD
#==========================

get_os_arch() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case "$os" in
        linux|darwin) ;;
        *) echo "Unsupported operating system: $os" >&2; return 1 ;;
    esac

    case "$arch" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) echo "Unsupported architecture: $arch" >&2; return 1 ;;
    esac

    echo "${os}-${arch}"
}

# Base URL for the Quilibrium releases
RELEASE_FILES_URL="https://releases.quilibrium.com/release"

# Get the current OS and architecture
OS_ARCH=$(get_os_arch)

# Fetch the list of files from the release page
# Updated regex to allow for an optional fourth version number
RELEASE_FILES=$(curl -s $RELEASE_FILES_URL | grep -oE "node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}(\.dgst)?(\.sig\.[0-9]+)?")

# Change to the download directory
mkdir -p ~/ceremonyclient/node
cd ~/ceremonyclient/node

# Download each file
for file in $RELEASE_FILES; do
    echo "Downloading $file..."
    curl -L -o "$file" "https://releases.quilibrium.com/$file"
    
    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded $file"
        # Check if the file is the base binary (without .dgst or .sig suffix)
        if [[ $file =~ ^node-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?-${OS_ARCH}$ ]]; then
            echo "Making $file executable..."
            chmod +x "$file"
            if [ $? -eq 0 ]; then
                echo "Successfully made $file executable"
            else
                echo "Failed to make $file executable"
            fi
        fi
    else
        echo "Failed to download $file"
    fi
    
    echo "------------------------"
done

echo "✅  Node binary download completed."