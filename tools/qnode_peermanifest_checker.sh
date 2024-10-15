#!/bin/bash

# This script installs grpcurl, jq, and base58 if they are not already installed,
# then retrieves peer information from a Quilibrium node.



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
                    ✨ QNODE PEER MANIFEST CHECKER ✨
===========================================================================
This script will retrieve your Quilibrium node peer manifest.

Follow the guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
===========================================================================

Processing... ⏳

EOF

sleep 7  # Add a 7-second delay


# Export some variables ot solve the gRPCurl not found error
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Install gRPCurl if not installed
if which grpcurl >/dev/null; then
    echo "✅ gRPCurl is installed."
else
    echo "❌ gRPCurl is not installed."
    echo "📦 Installing gRPCurl..."
    sleep 1  # Add a 1-second delay
    # Try installing gRPCurl using go install
    if go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest; then
        echo "✅ gRPCurl installed successfully via go install."
        echo
    else
        echo "⚠️ Failed to install gRPCurl via go install. Trying apt-get..."
        # Try installing gRPCurl using apt-get
        if sudo apt-get install grpcurl -y; then
            echo "✅ gRPCurl installed successfully via apt-get."
            echo
        else
            echo "❌ Failed to install gRPCurl via apt-get! Please install it manually."
            exit 1
        fi
    fi
fi

# Install jq if not installed
if ! command_exists jq; then
    echo "📦 Installing jq..."
    sudo apt-get install -y jq
fi

# Install base58 if not installed
if ! command_exists base58; then
    echo "📦 Installing base58..."
    sudo apt-get install -y base58
fi

# Command to retrieve peer information
get_peer_info_command="peer_id_base64=\$(grpcurl -plaintext localhost:8337 quilibrium.node.node.pb.NodeService.GetNodeInfo | jq -r .peerId | base58 -d | base64) && grpcurl -plaintext -max-msg-sz 5000000 localhost:8337 quilibrium.node.node.pb.NodeService.GetPeerManifests | grep -A 15 -B 1 \"\$peer_id_base64\""

# Demipoet code https://quilibrium.guide/manage-node/node-difficulty-metric#2-getting-your-node-difficulty-metric
#grpcurl -plaintext -max-msg-sz 5000000 localhost:8337 quilibrium.node.node.pb.NodeService.GetPeerManifests | less | grep -B 1 -A 16 $(echo -n Qmxxxxxxxxx | base58 -d | base64)

# Execute the command
echo "🚀 Retrieving peer information..."
eval $get_peer_info_command

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to retrieve peer information. Please make sure your Quilibrium node is running and accessible."
    echo "You can only retrieve the peer manifest on fresh nodes after 15-30 minutes that the node has been running."
    exit 1
fi

echo
echo
echo "🎉 Peer information retrieved successfully!"
