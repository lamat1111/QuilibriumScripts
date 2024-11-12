#!/bin/bash

cat << "EOF"

                    Q1Q1Q1\    Q1\   
                   Q1  __Q1\ Q1Q1 |  
                   Q1 |  Q1 |\_Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1 |  Q1 |  Q1 |  
                   Q1  Q1Q1 |  Q1 |  
                   \Q1Q1Q1 / Q1Q1Q1\ 
                    \___Q1Q\ \______|  QUILIBRIUM.ONE
                        \___|        
                              
===========================================================================
                 ✨ CEREMONYCLIENT CLEANUP TEST SCRIPT ✨
===========================================================================

This script will test the cleanup function for your node and qclient binaries.
It will show you what files would be deleted and what files would be kept.

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

EOF

# Set up test variables
NODE_DIR="$HOME/ceremonyclient/node"
CLIENT_DIR="$HOME/ceremonyclient/client"
release_os="linux"
[ "$(uname -m)" = "x86_64" ] && release_arch="amd64" || release_arch="arm64"

# The cleanup function
cleanup_old_releases() {
    local directory=$1
    local prefix=$2
    
    echo "⏳ Cleaning up old $prefix releases in $directory..."
    
    # Find the latest executable binary (will be the one we want to keep)
    local current_binary=$(find "$directory" -name "${prefix}-[0-9]*" ! -name "*.dgst" ! -name "*.sig*" -type f -executable 2>/dev/null | sort -V | tail -n 1)
    
    if [ -z "$current_binary" ]; then
        echo "❌ No current $prefix binary found"
        return 1
    fi
    
    # Get just the filename without the path
    current_binary=$(basename "$current_binary")
    echo "Current binary: $current_binary"
    
    # Find and delete old files in one go - simpler approach
    find "$directory" -type f -name "${prefix}-[0-9.]*-${release_os}-${release_arch}*" ! -name "${current_binary}*" -delete -print
    
    echo "✅ Cleanup completed for $prefix"
}

echo
echo "Current architecture: $release_os-$release_arch"
echo

# Test node cleanup
echo "Testing Node Cleanup..."
echo "------------------------"
echo "Current node files:"
ls -la "$NODE_DIR" | grep "node-"
echo "------------------------"
cleanup_old_releases "$NODE_DIR" "node"
echo "------------------------"
echo "Remaining node files:"
ls -la "$NODE_DIR" | grep "node-"
echo "------------------------"

# Test qclient cleanup
echo "Testing Qclient Cleanup..."
echo "------------------------"
echo "Current qclient files:"
ls -la "$CLIENT_DIR" | grep "qclient-"
echo "------------------------"
cleanup_old_releases "$CLIENT_DIR" "qclient"
echo "------------------------"
echo "Remaining qclient files:"
ls -la "$CLIENT_DIR" | grep "qclient-"

echo
echo "Test completed! Check the results above to see what was cleaned up."
echo