Certainly! Below is your script with the added functionality to restart the node using `service ceremonyclient restart` if it is not visible to the bootstrap peers.

```bash
cat << "EOF"

                      QQQQQQQQQ       1111111   
                    QQ:::::::::QQ    1::::::1   
                  QQ:::::::::::::QQ 1:::::::1   
                 Q:::::::QQQ:::::::Q111:::::1   
                 Q::::::O   Q::::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::1   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O     Q:::::Q   1::::l   
                 Q:::::O  QQQQ:::::Q   1::::l   
                 Q::::::O Q::::::::Q   1::::l   
                 Q:::::::QQ::::::::Q111::::::111
                  QQ::::::::::::::Q 1::::::::::1
                    QQ:::::::::::Q  1::::::::::1
                      QQQQQQQQ::::QQ111111111111
                              Q:::::Q           
                               QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


============================================================================
                ✨ NODE VISIBILITY CHECK + AUTORESTART ✨
============================================================================
This script will check if you node is visible to Bootstrap Peers.
It will autorestart your node if it is not visible.

Follow the Quilibrium Node guide at https://docs.quilibrium.one

Made with 🔥 by LaMat - https://quilibrium.one
============================================================================

Processing... ⏳

EOF

# Export some variables to solve the gRPCurl not found error
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# List of bootstrap peers
bootstrap_peers=(
"EiDpYbDwT2rZq70JNJposqAC+vVZ1t97pcHbK8kr5G4ZNA=="
"EiCcVN/KauCidn0nNDbOAGMHRZ5psz/lthpbBeiTAUEfZQ=="
"EiDhVHjQKgHfPDXJKWykeUflcXtOv6O2lvjbmUnRrbT2mw=="
"EiDHhTNA0yf07ljH+gTn0YEk/edCF70gQqr7QsUr8RKbAA=="
"EiAnwhEcyjsHiU6cDCjYJyk/1OVsh6ap7E3vDfJvefGigw=="
"EiB75ZnHtAOxajH2hlk9wD1i9zVigrDKKqYcSMXBkKo4SA=="
"EiDEYNo7GEfMhPBbUo+zFSGeDECB0RhG0GfAasdWp2TTTQ=="
"EiCzMVQnCirB85ITj1x9JOEe4zjNnnFIlxuXj9m6kGq1SQ=="
)

# Run command and capture output
output=$(grpcurl -plaintext localhost:8337 quilibrium.node.node.pb.NodeService.GetNetworkInfo)

# Check for bootstrap peers in the output
visible=false
for peer in "${bootstrap_peers[@]}"; do
    if [[ $output == *"$peer"* ]]; then
        visible=true
        echo "You see $peer as a bootstrap peer"
    else
        echo "Peer $peer not found"
    fi
done

if $visible ; then
    echo ""
    echo ""
    echo "✅ Your node is visible to bootstrap peers!"
    echo ""
else
    echo ""
    echo ""
    echo "❌ Your node is not visible. Restarting node..."
    sleep 3

    # Restart the node
    echo "🔄 Restarting the node..."
    if sudo service ceremonyclient restart; then
        echo "✅ Node restarted successfully."
    else
        echo "❌ Failed to restart the node. Please try restarting it manually."
    fi
fi
