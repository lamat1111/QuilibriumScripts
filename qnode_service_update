#!/bin/bash

# Stop the ceremonyclient service
service ceremonyclient stop

# Switch to the ~/ceremonyclient directory
cd ~/ceremonyclient

# Fetch updates from the remote repository
git fetch origin
git merge origin

# Switch to the ~/ceremonyclient/node directory
cd ~/ceremonyclient/node

# Clean and reinstall node
GOEXPERIMENT=arenas go clean -v -n -a ./...
rm /root/go/bin/node
GOEXPERIMENT=arenas go install ./...

# Start the ceremonyclient service
service ceremonyclient start
