#!/bin/bash

#!/bin/bash

HOME=$(eval echo ~$USER)
NODE_PATH="$HOME/ceremonyclient/node"
CONFIG_FILE="$NODE_PATH/.config/config.yml"
OLD_LINE="listenMultiaddr: /ip4/0.0.0.0/udp/8336/quic"
NEW_LINE="listenMultiaddr: /ip4/0.0.0.0/tcp/8336"


echo "This script will check if the line 'listenMultiaddr: /ip4/0.0.0.0/udp/8336/quic'"
echo "exists in the file '$HOME/ceremonyclient/node/.config/config.yml'. "
echo "If found, it will change it to 'listenMultiaddr: /ip4/0.0.0.0/tcp/8336'."
sleep 3

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found."
    exit 1
fi

# Check if the old line exists in the config file
if grep -q "$OLD_LINE" "$CONFIG_FILE"; then
    # Replace the old line with the new one
    sed -i "s/$OLD_LINE/$NEW_LINE/" "$CONFIG_FILE"
    echo "Success: Line changed in $CONFIG_FILE"
else
    echo "Error: The line $OLD_LINE does not exist in $CONFIG_FILE"
fi
