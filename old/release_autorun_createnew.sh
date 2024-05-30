#!/bin/bash

# Stop ceremonyclient service
echo "🛑 Stopping ceremonyclient service..."
service ceremonyclient stop
sleep 3

# Remove old release_autorun.sh
echo "🗑️ Removing old release_autorun.sh..."
rm ~/ceremonyclient/node/release_autorun.sh
sleep 1

# Create new release_autorun.sh
echo "📝 Creating new release_autorun.sh..."
cat <<EOF > ~/ceremonyclient/node/release_autorun.sh
#!/bin/bash

start_process() {
    version=\$(cat config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")
    if [[ "\$OSTYPE" == "linux-gnu"* ]]; then
        if [[ \$(uname -m) == "aarch64"* ]]; then
            ./node-\$version-linux-arm64 &
            main_process_id=\$!
        else
            ./node-\$version-linux-amd64 &
            main_process_id=\$!
        fi
    elif [[ "\$OSTYPE" == "darwin"* ]]; then
        ./node-\$version-darwin-arm64 &
        main_process_id=\$!
    else
        echo "unsupported OS for releases, please build from source"
        exit 1
    fi

    echo "process started with PID \$main_process_id"
}

is_process_running() {
    ps -p \$main_process_id > /dev/null 2>&1
    return \$?
}

kill_process() {
    local process_count=\$(ps -ef | grep "node-\$version" | grep -v grep | wc -l)
    local process_pids=\$(ps -ef | grep "node-\$version" | grep -v grep | awk '{print \$2}' | xargs)

    if [ \$process_count -gt 0 ]; then
        echo "killing processes \$process_pids"
        kill \$process_pids
    else
        echo "no processes running"
    fi
}

kill_process

start_process

while true; do
    if ! is_process_running; then
        echo "process crashed or stopped. restarting..."
        start_process
    fi

    git fetch

    local_head=\$(git rev-parse HEAD)
    remote_head=\$(git rev-parse @{u})

    if [ "\$local_head" != "\$remote_head" ]; then
        kill_process

        git pull

        start_process
    fi

    sleep 43200
done
EOF

# Give permissions
echo "🔑 Giving permissions to release_autorun.sh..."
chmod +x ~/ceremonyclient/node/release_autorun.sh
sleep 2

# Start ceremonyclient service
echo "🚀 Starting ceremonyclient service..."
service ceremonyclient start
sleep 2

# Show node log
echo "📜 Displaying node log..."
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
