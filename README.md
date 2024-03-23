


## This is a script to auto-install your Quilibrium node in the easiest way. 

**&#x2661; Want to say thank you?**

Apart from using my referral links below for Cherryservers, you can buy me a cup of something with a small donation, here is my ERC-20 address
```
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013
```


## Table of Contents

- [Best Server to Run a Quilibrium Node](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#best-server-to-run-a-quilibrium-node)
- [Node auto-installer: how to use the script](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#node-auto-installer-how-to-use-the-script)
- [Backup Your keys.yml and config.yml Files](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#backup-your-keysyml-and-configyml-files)
- [Tools and resources](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#tools-and-resources)
- [Useful Server Commands](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#useful-server-commands)
- [Migrate Node to a New Server](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#migrate-node-to-a-new-server)
- [Setup the Firewall and gRPC Calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-firewall-and-grpc-calls)
- [Troubleshooting](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#troubleshooting)


## Best server to run a Quilibrium node
[Cherryservers](https://www.cherryservers.com/?affiliate=CRXA3YWE) support Quilibrium, is suggested by Cassie (Quilibrium founder), and they offer good solutions for a fair price. Thank you for using my referral links and supporting my work :-)

Here are some pre-configured server options, take a look.
[Cloud VDS 4](https://www.cherryservers.com/server-customizer/cloud_vds_4?affiliate=CRXA3YWE) | [E3-1240V3](https://www.cherryservers.com/server-customizer/e3_1240v3?affiliate=CRXA3YWE) | [E3-1240V5](https://www.cherryservers.com/server-customizer/e3_1240v5?affiliate=CRXA3YWE) | [E5-1620V4](https://www.cherryservers.com/server-customizer/e5_1620v4?affiliate=CRXA3YWE) | [E5-1650V3](https://www.cherryservers.com/server-customizer/e5_1650v3?affiliate=CRXA3YWE) | [E5-1650V4](https://www.cherryservers.com/server-customizer/e5_1650v4?affiliate=CRXA3YWE)





## Node auto-installer: how to use the script
### Step 1
If you are reinstalling your existing node, be sure to backup your keys.yml and config.yml files, they are in the root/ceremonyclient/node/.config folder. [How do I do this?](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#backup-your-keysyml-and-configyml-files)
### Step 2
Run the auto-installer script on your server (OS must be Ubuntu 22.04.X)
```
 wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer | bash
```

<blockquote>
<details>
 <summary>Auto-installer script for Almalinux 8 (untested)</summary>
 The below script has not been tested yet, run it at you own risk!
 
 
 ```
 wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-ubuntu-almalinux | bash
```

</details>
</blockquote>

### Step 3
After installing the node and making some necessary edits, the script will run your node for 5 minutes and then you will be prompted to reboot the system, type "Y" and reboot.
### Step 4
Wait 3 minutes, then login again in your server.
### Step 5
Run the command below. This will go to the node folder, create a persistent shell (session), run the poor_mans_cd script and detach from the session again.
      
  ```
  cd ceremonyclient/node && tmux new-session -d -s quil './poor_mans_cd.sh' && tmux detach
  ```
  <blockquote>
  <details>
   <summary>Alternatve: step by step commands</summary>
   You can also run these command one after the other if you prefer.
  
   ```
  cd ceremonyclient/node 
  ```
  
  ```
  tmux new-session -s quil 
  ```
  
  ```
  ./poor_mans_cd.sh
  ```
To detach from tmux press CTRL+B then D. Now you can safely logout from your server and the node will keep running in its persistent shell.
To reattach to the tmux session and see your node log, just use `tmux a -t quil`
</details>
</blockquote>

### Step 6
Now you can safely logout from your server and the node will keep running in its persistent shell.
</br>
</br>
If you want to see you node log you can reattach to the tmux session with `tmux a -t quil`

Once you are in the tmux session a green bar will appear at the bottom of the screen, to detach from tmux press CTRL+B then D.

It will usually take 15-30 minutes before you will begin to see new log entries in the node log.

The poor_mans_cd is a script used to run the node, it will also restart it if it gets killed and will auto-update it when there is a new version available.

## Backup your keys.yml and config.yml files
Use [WinSCP](https://winscp.net/eng/index.php) to navigate to the `root/ceremonyclient/node/.config`  folder. You may have to enable visibility for hidden files in WinSCP if you don't see the .config folder. Select Options, Preferences from the main menu, then the Panels tab, and check the option to Show hidden files (Ctrl+Alt+H).

Download locally your `keys.yml` and `config.yml` files. Keep them safe and do not share them with anyone!

If you need to migrate the node elsewhere, after installing the node from scratch you just need to put these 2 files in the `root/ceremonyclient/node/.config`  folder (changing the ones automatically created by the node). Here is a [quick way to do this](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#migrate-node-to-a-new-server).

------
------

## Tools and resources
 - To manage your nodes use [Termius](https://termius.com/), the coolest SSH client and terminal around :) 
 - To track your server uptime and  resources usage use [Hetrixtools.com](https://hetrixtools.com/), you can track up to 15 servers for free and the setup is very easy
 - If you need help come to the [Quilibrium Community Discord](https://discord.gg/quilibrium)

## Useful server commands

<details>
<summary>Check node version</summary>

```bash
cat ~/ceremonyclient/node/config/version.go | grep -A 1 'func GetVersion() \[\]byte {' | grep -Eo '0x[0-9a-fA-F]+' | xargs printf '%d.%d.%d'
```

</details>

<details>
<summary>Get node peer ID</summary>

```bash
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -peer-id
```

</details>

<details>
<summary>Check QUIL balance</summary>

```bash
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas /root/go/bin/node -balance
```

</details>

<details>
<summary>Attach to existing tmux session</summary>

```bash
tmux a -t quil
```

To detach from tmux press CTRL+B then release both keys and press D
</details>

## Migrate node to a new server
1. Use the auto-installer script in this guide to install the node on the new server and let it run for 5 minutes.
2. Grab your new server IP and password.
3. Login to the old server and run this command.
Change <NEW_SERVER_IP> with your new server IP and enter the new server password when requested.

```bash
scp -f /root/ceremonyclient/node/.config/keys.yml /root/ceremonyclient/node/.config/config.yml root@<NEW_SERVER_IP>:/root/ceremonyclient/node/.config/
```
<blockquote>
ATTENTION: The command will ovewrite any existing keys.yml and config.yml files in the target server with no confirmation.

The command will move your keys.yml and config.yml to new server. For this to work the node must already be installed in the new server and the .config folder be generated.
</blockquote>

## Setup the Firewall and gRPC calls
Run the below script to setup the Firewall and gRPC calls automatically. You need to install the node first and let it run for 5 minutes in order to generat its .config folder.
```bash
wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-gRPC-and-firewall | bash
```
## Troubleshooting
<details>
<summary>Errors on servers that already hosted a node</summary>
If you've already attempted to install a node on your server and then ran the auto-install script, you may encounter errors. Execute these commands sequentially, and they should typically suffice for initiating a new installation.
 
```bash
sudo swapoff /swap/swapfile 2>/dev/null; sudo sed -i '/\/swap\/swapfile/d' /etc/fstab; sudo rm /swap/swapfile 2>/dev/null; sudo rmdir /swap 2>/dev/null || sudo rm -rf /swap
```
```bash
sudo rm -rf /usr/local/go && sudo rm -rf /root/ceremonyclient
```
</details>
<details>
<summary>poor_mans_cd: command not found</summary>
If when running the poor_mans_cd.sh script in your tmux session you get this error

./poor_mans_cd.sh: line 4: go: command not found

then press CTRL+C and then run this command
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go
export GOEXPERIMENT=arenas
```
then try to run again the script 
```bash
./poor_mans_cd.sh
```
This solution in general works everytime you receive the error: Command 'go' not found
</details>

