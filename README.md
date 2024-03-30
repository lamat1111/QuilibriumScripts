





## This is a script to auto-install your Quilibrium node in the easiest way. 

*This guide is unofficial and made just to support the project*

**&#x2661; Want to say thank you?**

Apart from using my referral links below for Cherryservers, you can buy me a cup of something with a small donation, here is my ERC-20 address
```
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013
```


## Table of Contents

- [Best Server to Run a Quilibrium Node](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#best-server-to-run-a-quilibrium-node)
- [Node auto-installer: how to use the script](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#node-auto-installer-how-to-use-the-script)
- [Backup Your keys.yml and config.yml Files](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#backup-your-keysyml-and-configyml-files)
- [Setup the Firewall and gRPC Calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-firewall-and-grpc-calls)
- [Tools and resources](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#tools-and-resources)
- [Useful Server Commands](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#useful-server-commands)
- [Migrate Node to a New Server](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#migrate-node-to-a-new-server)
- [Troubleshooting](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#troubleshooting)


## Best server to run a Quilibrium node
*Here some good options. This section is still under construction as I collect reviews from others. Thank you for using my referral links and supporting my work :-)*

<details>
 <summary>Cherryservers</summary>
 <p><a href="https://www.cherryservers.com/?affiliate=CRXA3YWE">Cherryservers</a> supports Quilibrium and is recommended by Cassie, the founder of Quilibrium. They offer good solutions at a fair price.</p>
 <p>Here are some pre-configured server options, take a look.</p>
 <ul>
   <li><a href="https://www.cherryservers.com/server-customizer/cloud_vds_4?affiliate=CRXA3YWE">Cloud VDS 4</a></li>
   <li><a href="https://www.cherryservers.com/server-customizer/e3_1240v3?affiliate=CRXA3YWE">E3-1240V3</a></li>
   <li><a href="https://www.cherryservers.com/server-customizer/e3_1240v5?affiliate=CRXA3YWE">E3-1240V5</a></li>
   <li><a href="https://www.cherryservers.com/server-customizer/e5_1620v4?affiliate=CRXA3YWE">E5-1620V4</a></li>
   <li><a href="https://www.cherryservers.com/server-customizer/e5_1650v3?affiliate=CRXA3YWE">E5-1650V3</a></li>
   <li><a href="https://www.cherryservers.com/server-customizer/e5_1650v4?affiliate=CRXA3YWE">E5-1650V4</a></li>
 </ul>
</details>
<details>
 <summary>Perfect Quality Hosting</summary>
 <p><a href="https://pq.hosting/?from=650641">Perfect Quality Hosting</a> is another good option.</p>
</details>

## Node auto-installer: install your node in a few clicks

*If you are reinstalling your existing node, be sure to backup your keys.yml and config.yml files, they are in the root/ceremonyclient/node/.config folder. [How do I do this?](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#backup-your-keysyml-and-configyml-files)*

### Step 1
**Rent a server with at least 8 cores (best 12), 16 GB RAM (best 32), 250 GB SSD space (best 500), and 400 Mbit/s symmetric bandwidth.**<br>
*(After Quilibrium 1.5 min specs will be: 4 cores, 8 GB RAM, and 400 Mbit/s symmetric bandwidth. Outbound traffic after 1.5 should be up to 5 TB per month ((raw approximation)), depending on how you set the node)*<br>
Also refer to the [Quilibrium official docs](https://quilibrium.com/docs/noderunning).<br>
If you can afford better specs than the minimum, your node will earn more rewards.

VDS (Virtual Dedicated Servers) and Bare Metal (Physical dedicated Servers) are your best choiche. Using a VPS (Virtual Private Server) may give you issues as often the providers oversell the resources. The community had a really bad experience with both Contabo and Hostinger for instance.<br>
That being said, after 1.5 is out a VPS or a home machine may work just fine.
### Step 2
**Install the OS Ubuntu 22.04.X.**<br>
If your server has two disks, consider configuring them in "RAID 1" (typically offered by your provider). This setup mirrors one disk to the other, providing redundancy and safeguarding against data loss in case one disk fails.

### Step 3
Run the auto-installer script on your server (OS must be Ubuntu 22.04.X). I suggest you to use [Termius](https://termius.com/) to login 
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

### Step 4
After installing the node and making some necessary edits, the script will run your node for 5 minutes and then you will be prompted to reboot the system, type "Y" and reboot.
### Step 5
Wait 3 minutes, then login again in your server.
### Step 6
Run the command below. This will go to the node folder, create a persistent shell (session), start the node via the *poor_mans_cd* script (more info about this script below) and detach from the session again.
      
  ```
  cd ceremonyclient/node && tmux new-session -d -s quil './poor_mans_cd.sh'
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

### Step 7
**You are done!** Now you can safely logout from your server and the node will keep running in its persistent shell.
</br>
</br>
If you want to see you node log you can reattach to the tmux session with `tmux a -t quil`

Once you are in the tmux session a green bar will appear at the bottom of the screen, to detach from tmux press CTRL+B then D.<br>
It will usually take 15-30 minutes before you will begin to see new log entries in the node log.

The poor_mans_cd is a script used to run the node, it will also restart it if it gets killed and will auto-update it when there is a new version available.

### Step 8
Let you node run for at least 30 minutes, then proceed to [backup your your keys.yml and config.yml files](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#backup-your-keysyml-and-configyml-files), and [setup your gRPC calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-firewall-and-grpc-calls)

### Check node info
After you node has been running for at least 30 minutes, run this command from your root folder to check the node info (Node version, Peer ID, Quil balance).<br>
For this to work you need to [setup the gRPC calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-firewall-and-grpc-calls) first.
  ```
cd /root/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -node-info
  ```
*If the above command does not work, or you have not set the gRPC calls, there are alternative commands to check you PeerID and node version, just look in [Useful Server Commands](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#useful-server-commands)*

## Backup your keys.yml and config.yml files
After 30 minutes that then node has been running, it should have generated your keys and config files correctly.
Use [WinSCP](https://winscp.net/eng/index.php) to navigate to the `root/ceremonyclient/node/.config`  folder. You may have to enable visibility for hidden files in WinSCP if you don't see the .config folder. Select Options, Preferences from the main menu, then the Panels tab, and check the option to Show hidden files (Ctrl+Alt+H).

Download locally your `keys.yml` and `config.yml` files. Keep them safe and do not share them with anyone!
Is a good idea to put them in an encrypted folder using a free tool such as [Encrypto](https://macpaw.com/encrypto)

If you need to migrate the node elsewhere, after installing the node from scratch you just need to put these 2 files in the `root/ceremonyclient/node/.config`  folder (changing the ones automatically created by the node). Here is a [quick way to do this](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#migrate-node-to-a-new-server).

## Setup the Firewall and gRPC calls
### Setup the Firewall
Run the below script to setup the Firewall.
```bash
wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-firewall | bash
```
### Setup the gRPC calls
After your node has been running for 30 minutes, run the below script to setup the gRPC calls.
```bash
wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-gRPC-calls | bash
```
<blockquote>
Some users have reported errors after running the above script. To be safe you can also update your config.yml manually to enable the gRPC calls.
 </blockquote>
<details>
 <summary>How to enable gRPC calls manually</summary>
1. Open the file root/ceremonyclient/node/.config/config.yml on your local pc using WinSCP<br>
 
2. Find <code>listenGrpcMultiaddr: “”</code> (end of the file) and replace it with  <code>listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337</code><br>

3. Find <code>engine:  </code>(about the middle of the file) and paste<code>  statsMultiaddr: "dns/stats.quilibrium.com/tcp/443"</code> right below it, with two empty spaces before the line<br>

4. Save the file
</details>




------
------
------

## Tools and resources
 - To manage your nodes use [Termius](https://termius.com/), the coolest SSH client and terminal around :) 
 - To track your server uptime and  resources usage use [Hetrixtools.com](https://hetrixtools.com/), you can track up to 15 servers for free and the setup is very easy
 - If you need help come to the [Quilibrium Community Discord](https://discord.gg/quilibrium)

## Useful server commands

<details>
<summary>Check node info</summary>
After you node has been running for at least 30 minutes, run this command from your root folder to check the node info (Node version, Peer ID, Quil balance).<br>
For this to work you need to [setup the gRPC calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-firewall-and-grpc-calls) first.<br>
To go to the root folder just type cd .
 
  ```
cd /root/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -node-info
  ```
</details>
<br>
<details>
<summary>Check node version</summary>
If the "Check node info" command above do not work, you can check the node version by running:
 
  ```
cat ~/ceremonyclient/node/config/version.go | grep -A 1 'func GetVersion() \[\]byte {' | grep -Eo '0x[0-9a-fA-F]+' | xargs printf '%d.%d.%d'
  ```
</details>
<details>
<summary>Check node peer ID</summary>
If the "Check node info" command above do not work, you can check the node peer ID by running:
 
  ```
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -peer-id
  ```
</details>
<details>
<summary>Attach to existing tmux session</summary>
 
```bash
tmux a -t quil
```
To detach from tmux press CTRL+B then release both keys and press D
</details>
<details>
<summary>Create tmux session + run node + detach from session: 1 step command</summary>
This is useful to quickly run then node in a session AFTER you have rebooted your server. Only RUN this after a reboot and if you have no tmux session already active.
 
```bash
cd ceremonyclient/node && tmux new-session -d -s quil './poor_mans_cd.sh' && tmux detach
```
 </details>
 <details>
<summary>Create cronjob to run the node automatically after a reboot</summary>
You only have to run this command once. This will setup a cronjob that will create your tmux session and run the node automatically after every reboot of your server.
Shoutout to Peter Jameson (Quilibrium Discord community creator) for the script.
 
```bash
(crontab -l ; echo "@reboot sleep 10 && bash -lc \"tmux new-session -d -s quil\" && tmux send-keys -t quil \"cd ~/ceremonyclient/node\" Enter && tmux send-keys -t quil \"./poor_mans_cd.sh\" Enter") | crontab -
```
 </details>
<details>
<summary>Kill node process</summary>
Use this in case you need to stop the node and kill the process
 
```bash
pkill node && pkill -f "go run ./..."
```
</details>
<details>
<summary>Empty "store" folder</summary>
CAREFUL: this will empty your "store" folder, only use it if you know what you are doing.
Sometimes when you receive errors that you cannot debug, you can solve by killing the node process, emptying the store folder and starting the node again from scratch.
 
```bash
sudo rm -r /root/ceremonyclient/node/.config/store
```
</details>
</details>
<details>
<summary>Backup keys.yml and config.yml to a root/backup folder</summary>
This may be useful if you have to cleanup your ceremonyclient folder and don't want to download locally your config.yml and keys.yml. You can just backup them remotely on a root/backup folder and copy them again in the node folder later on.

Copy the files from your node folder to the root/backup folder
```bash
mkdir -p /root/backup && cp /root/ceremonyclient/node/.config/config.yml /root/backup && cp /root/ceremonyclient/node/.config/keys.yml /root/backup
```

Copy the files back from root/backup to your node folder (a copy will also remain in the root/backup folder)
```bash
cp /root/backup/{config.yml,keys.yml} /root/ceremonyclient/node/.config/
```
</details>

## Migrate node to a new server
1. *OPTIONAL if you already have installed the node*. Use the auto-installer script in this guide to install the node on the new server and let it run for 5 minutes, then stop it with CTRL+C
2. Grab your new server IP and password.
3. Login to the old server and run this command.
*Change <NEW_SERVER_IP> with your new server IP and enter the new server password when requested.*

```bash
scp -f /root/ceremonyclient/node/.config/keys.yml /root/ceremonyclient/node/.config/config.yml root@<NEW_SERVER_IP>:/root/ceremonyclient/node/.config/
```
<blockquote>
ATTENTION: The command will ovewrite any existing keys.yml and config.yml files in the target server with no confirmation.

The command will move your keys.yml and config.yml to new server. For this to work the node must already be installed in the new server and the .config folder be generated.
</blockquote>

### Manual method
Alternatively you can migrate the files manually. If you already have a local backup of the config.yml and keys.yml files, you just need to upload them to your new server in the folder `root/ceremonyclient/node/.config` . You can use use [WinSCP](https://winscp.net/eng/index.php) to do this.

## Troubleshooting
<details>
<summary>Panic: resource temporarily unavailable</summary>
This error means you have an already running instance of the node. Follow the step below to kill all nodes and restart just one instance.
</details>
<details>
<summary>How to kill and restart the node</summary>
Sometimes you may need to kill and restart the node. For instance if you made the mistake of starting 2 separate instances of the node.<br>
You may also verify this by running the command <code>ps -ef</code> . It will list all your running processes, look for ".../exe/node". There should be only one.

<br><br>
Go to your root folder

```bash
cd root
```
Kill all the node processes
```bash
pkill node && pkill -f "go run ./..."
```
Go into your tmux session and start again the node.
  ```
  tmux a -t quil
  ```
  
  ```
  ./poor_mans_cd.sh
  ```
To detach from tmux press CTRL+B then D.
</details>

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
<summary>Command GO not found</summary>
If you see the error *Command GO not found*, then try to run this command.
 
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go
export GOEXPERIMENT=arenas
```
<br><br>
If you receive the error while trying to run your *poor_mans_cd* script in your tmux session, press CTRL+C to stop the process, then run 
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go
export GOEXPERIMENT=arenas
```
and finally try to run again the script 
```bash
./poor_mans_cd.sh
```
</details>

<details>
<summary>Remove gRPC calls settings from config.yml</summary>
If you want to remove the gRPC calls setting from your config.yml file here is what you have to do:<br>
1. Open the file root/ceremonyclient/node/.config/config.yml on your local pc using WinSCP<br>
2. Find <code>listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337</code> and replace it with <code>listenGrpcMultiaddr: “”</code><br>
3. Find <code>statsMultiaddr: "dns/stats.quilibrium.com/tcp/443"</code> and remove the line completely<br>
now your config.yml should be as it was generated by the node itself
</details>
<details>
<summary>How to debug your config.yml</summary>
A simple way to debug your config.yml file if you are not a dev is to create a node from scratch an download locally the config.yml file.
Then download the config.yml of your working node, the one you have edited either via a script or manually.

At this point use a tool such as Diffinity - https://truehumandesign.se/s_diffinity.php, to compare the 2 files.

The encryption keys will be different of course, and you may have some more lines in the "bootstrapPeers" section of one of the files, but you should easily see the lines you have added or if there is any typing error in the file you edited.
</details>
