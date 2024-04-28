
# Quilibrium node step by step installation
>[!NOTE]
>This is a step by step process alternative to the node auto-installer script. Always refer to this [node setup guide](https://github.com/lamat1111/quilibrium-node-auto-installer) for any other info or assistance.

*(...) following up from [step 2 of the main guide](https://github.com/lamat1111/quilibrium-node-auto-installer?tab=readme-ov-file#step-2).*

Simply run the commands one by one by copy/pasting. When several commands are grouped, you can safely copy paste all of them at the same time and they will be executed sequentially. 

---

Update the package lists to ensure the latest versions are available.
```
sudo apt -q update
```
Install necessary packages: git, wget, tmux, and tar.
```
sudo apt-get install git wget tmux tar -y
```
Download and extract the required version of Go
```
wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
sudo rm go1.20.14.linux-amd64.tar.gz
```
Update PATH and GOPATH environment variables in ~/.bashrc.
```
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GO111MODULE=on' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
source ~/.bashrc
```
Create and configure swap space
```
sudo mkdir /swap && sudo fallocate -l 24G /swap/swapfile && sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile && sudo swapon /swap/swapfile
sudo bash -c 'echo "/swap/swapfile swap swap defaults 0 0" >> /etc/fstab'
```
Modify network buffer sizes for better performance
```
sudo bash -c 'echo -e "\nnet.core.rmem_max=600000000" >> /etc/sysctl.conf'
sudo bash -c 'echo -e "\nnet.core.wmem_max=600000000" >> /etc/sysctl.conf'
sudo sysctl -p
```
Create some useful folders
```
mkdir -p /root/backup/ /root/scripts/ /root/scripts/log/
```
Create /root/scripts/qnode_restart.sh (simple script to start the node and restart it automatically if it stops)
```
sudo wget -O /root/scripts/qnode_restart.sh -N https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/qnode_restart && sudo chmod +x /root/scripts/qnode_restart.sh
```
Reboot your server.
```
sudo reboot
```

Now continue [here](https://github.com/lamat1111/quilibrium-node-auto-installer?tab=readme-ov-file#step-5)
