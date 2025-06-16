# Schneider Electric EcoStruxure Building Operation

Open, flexible, data-centric. Go beyond traditional building management system functionality to create smart, future-ready buildings with EcoStruxure Building Operation. Part of the EcoStruxure Building integrated smart building platform; this open, flexible, data-centric solution provides a single control center to monitor, manage and optimize all types of buildings.

To learn more, see [EcoStruxure Building](https://www.se.com/ww/en/work/products/product-launch/building-management-system/)

EcoStruxure Building Operation Edge Server is subject to commercial licensing. Contact your local [Schneider Electric representative](https://www.se.com/ww/en/work/support/country-selector/distributors.jsp) for more information.

## Raspberry Pi version
This repository is tailored to run Schneider Electric Enterprise Server on Raspberry Pi OS. By leveraging QEMU emulation (`qemu-user-static` and `qemu-user-binfmt`), it is possible to use the official amd64 Docker image on an aarch64 board without modification.

These adjustments allow you to deploy and operate the server seamlessly on ARM hardware.

The examples below use Enterprise Server version `7.0.2.348`.

To download the Enterprise Server image run:
```
docker pull ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
```

### Dependencies
Install Docker and QEMU emulation support so the amd64 image works on Raspberry Pi OS.\
Eseguire i comandi uno alla volta, attendendo il completamento di ognuno prima di proseguire:

```bash
sudo apt update -y
```

```bash
sudo apt full-upgrade -y
```

```bash
sudo apt install -y docker.io
```

```bash
sudo apt install -y qemu-user-binfmt
```

```bash
sudo apt install -y qemu-user-static
```

Verify the emulation with:
```bash
docker run --rm --platform linux/amd64 hello-world
```

## System Requirements

The image for EcoStruxure Building Operation Enterprise Server is about
697&nbsp;MB. Plan for at least a couple of gigabytes of free disk space to
accommodate the container's database volume and log files. The server can run
with as little as 1&nbsp;GB of RAM, but allocating 2&nbsp;GB or more is
recommended. See Schneider Electric's
[official hardware specifications](https://ecostruxure-building-help.se.com/) for
complete details.

## How to use this image
For full functionality, valid and activated licenses are required. See official Building Operation documentation for more information.

To manage the containers we do provide a few docker scripts to use as is or to draw inspiration from:
[user-scripts](./user-scripts)

After downloading the image with `docker pull`, start the Enterprise Server
using the provided script or the command shown below.

```bash
./user-scripts/start-host-es.sh [--swarm]
```

This script simply runs:
```bash
docker run -d --network bridged-net \
    --platform linux/amd64 \
    --ulimit core=-1 \
    --restart always \
    --mount type=bind,source=/var/crash,target=/var/crash \
    -e NSP_ACCEPT_EULA="Yes" \
    --mount source=EnterpriseServer-db,target=/var/EBO \
ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
```
When called with `--swarm`, the script creates an equivalent `docker service`.

Before running the script, make sure `/var/crash` exists on the host:

```bash
sudo mkdir -p /var/crash
```

### Network
We recommend that you use this container with an IPvlan network. This to give the container its own IP address on the local network for simple communication with for example BACnet devices on the same network.

If you run the script, like this:
```
./create-bridged-network 192.168.1.0/24 192.168.1.1 eth0
```
It will create a network called "bridged-net".
* The first parameter is the subnet (in the example above 192.168.1.0/24) matching the subnet for the host machine.
```
#find your subnet
ip -o -f inet addr show | awk '/scope global/ {print $4}'
```
* The second parameter is the gateway (in the example above 192.168.1.1)
```
# find your gateway
ip route | grep default
# Example output:
default via 10.142.16.1 dev eth0 proto dhcp src 10.142.16.223 metric 100
# in this example the gateway is 10.142.16.1
```

* The third parameter is the name of the network interface on the host machine (in this example eth0)
```
ip ad
# Example output:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp4s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 10:7b:44:a3:39:a1 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.251/24 brd 192.168.1.255 scope global dynamic noprefixroute enp4s0
       valid_lft 1497sec preferred_lft 1497sec
    inet6 fe80::5f24:6a3e:43cc:c39f/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
# in this example the interface is enp4s0
```



Then you need to have a free IP address in that subnet to set as a static address for your container.

### Host ↔ Container communication
With a network created using `create-bridged-network` the host cannot
communicate with containers by default. Create a macvlan interface on the
Raspberry Pi so that the host and containers share the same LAN.

```bash
sudo ip link add mac0 link eth0 type macvlan mode bridge
sudo ip addr add 192.168.1.254/24 dev mac0
sudo ip link set mac0 up
```

Verify connectivity:

```bash
# from the Pi
ping -c3 192.168.1.11

# from the container
docker exec -it bacnet_client ping -c3 192.168.1.10
```

To make the interface persistent with `systemd-networkd` create
`/etc/systemd/network/99-macvlan.netdev`:

```ini
[NetDev]
Name=mac0
Kind=macvlan

[MACVLAN]
Mode=bridge
```

and `/etc/systemd/network/99-macvlan.network`:

```ini
[Match]
Name=mac0

[Network]
Address=192.168.1.254/24
```

Then restart networkd:

```bash
sudo systemctl restart systemd-networkd
```

### EULA
The End-User License Agreement (EULA) must be accepted before the server can start.
    The license terms for this product can be downloaded here: [EULA](https://ecostruxure-building-help.se.com/bms/Topics/Show.castle?id=14865)

### Start


Then to start your server:
```
./start.py --name=cs3 --version=7.0.2.348 --ip=192.168.1.3 --type=ebo-enterprise-server --accept-eula=Yes [--swarm]
```
You can interact with the server via your browser: https://192.168.1.3/.
Initial user name: admin, password: admin
The version and IP are only examples.
By default the server type is an Edge Server.
To start an Enterprise Server or Enterprise Central instead. add --type=ebo-enterprise-server or --type=ebo-enterprise-central

If you prefer running Docker directly:
```bash
docker run -d --platform linux/amd64 --name=cs3 -h cs3 \
    --ulimit core=-1 \
    --restart always \
    --network bridged-net \
    --mount type=bind,source=/var/crash,target=/var/crash \
    -e NSP_ACCEPT_EULA="Yes" \
    --ip 192.168.1.3 \
    --mount source=cs3-db,target=/var/sbo \
    ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
```

### Upgrade
To upgrade the server, use the same parameters as for start, but with the new version.

```
./upgrade.py --name=cs3 --version=7.0.2.348 --ip=192.168.1.3 --type=ebo-enterprise-server --accept-eula=Yes [--swarm]
```
The version and IP are only examples
### Backup management
There are also three scripts for backup management, for more details look in the scripts:

list-backups
```
./list-backups cs3
Server 1 2022-09-09 14_12_36_7.0.2.348.xbk
```

copy-backups
```
./copy-backups cs3 /tmp
```

restore-backup

Can be used with a backup file on the host machine or one of the backup files listed by list-backups. Options
* ConfigurationOnly
* AllData

```
# With just the name of the backup if you want to use the backup already available in the container
# note that you need to escape spaces in the backup name
./restore-backup cs3 7.0.2.348 Server\ 1\ 2022-09-09\ 14_12_36_7.0.2.348.xbk ConfigurationOnly
# Or with a path to a backup on the host if you want to use a backup from the host
./restore-backup cs3 7.0.2.348 /home/user/Server\ 1\ 2022-09-09\ 14_12_36_7.0.2.348.xbk ConfigurationOnly
```

## CA certificates
To install CA certificates in the container, you can either mount a host folder with your ca certificates by adding this parameter to your start.py script:
```
--ca-folder=/home/user/ca-certificates
```
Or you could build your own image on top of our image with the certificates added to: /usr/local/share/ca-certificates.
The CA certificates must have a .crt extension.
.
## Proxy
The script start.py (and upgrade.py) will pick up the proxy environment variables from the host and pass them on to the container. If you want to use other settings you can supply them with these parameters:
--http-proxy
--https-proxy
--no-proxy
The environment variables are, http_proxy, https_proxy and no_proxy in both lower and upper case.


## In case of crash
You can enable the container to send crash dumps to Schneider Electric, by setting the kernel core pattern of the host to:
```
sudo sysctl -w kernel.core_pattern=/var/crash/%t.%E.h%h.P%P.s%s.g%g.u%u.core
```
Apport wants to set the default pattern so to persist the core pattern, you need to disable apport.
```
sudo nano /etc/default/apport
```
change to:
```
enabled=0
```
To set the core pattern at boot:
```
 sudo nano /etc/sysctl.d/99-sysctl.conf
```
at the end of this file add:
```
kernel.core_pattern = /var/crash/%t.%E.h%h.P%P.s%s.g%g.u%u.core
```

The host also need to allow crash dumps, like this, then restart the host:
```
sudo nano /etc/security/limits.conf
# add these lines at the end
* soft core unlimited
* hard core unlimited
```
The container will look for dump files in /var/crash from the core_pattern above. That folder used must be writable by other or by the user/group 60606 used by the container.
Working DNS is also a prerequisite for the container to be able to send the crash information to Schneider Electric, see below.


## DNS
If your container can't reach the dns setup on your host, for example because of VPN. There are an optional parameter to the start script:
```
--dns=<some IP for a public dns>
```

## Set server in Password Reset Mode

To set server in Password Reset Mode, run the script with name and version as arguments.



```
./password-reset-mode cs3 7.0.2.348
```

## A few useful docker commands
If you have started a server named cs1.
Show log:
```
docker logs cs1
# and to follow the log, quit with Ctrl+C
docker logs -f cs1
```
Show running containers:
```
docker ps
# also show the stopped containers
docker ps -a
```

Stop the server:
```
docker stop cs1
```
Remove the container, to be able to start it again. Database will be kept:
```
docker rm cs1
```
List volumes (databases):
```
docker volume ls
```
Remove the database to start from scratch:
```
docker volume rm cs1-db
```
If you want to play with a server without the need to talk to devices you can start it with port forwarding like this:
```
docker run -d --name=cs1 -hostname=cs1 -p 1080:80 -p 1443:443 -p14444:4444 -e NSP_ACCEPT_EULA=Yes ghcr.io/schneiderelectricbuildings/ebo-enterprise-server:7.0.2.348
```
In this example you can connect to it on:
https://localhost:1443
The http-port is 1080 on the host machine.
The tcp-port is 14444 on the host machine.
It runs the example version 7.0.2.348.
It is namned cs1.

## Docker Swarm
Docker Swarm allows you to manage multiple Raspberry Pi nodes as a single cluster.
Initialize the swarm on the master node:
```bash
docker swarm init --advertise-addr <IP_of_master>
```
Join additional nodes as workers using the join token printed by the init command:
```bash
docker swarm join --token <token> <IP_of_master>:2377
```
To start the Enterprise Server as a swarm service use the scripts with the `--swarm` option.
```bash
./user-scripts/start-host-es.sh --swarm
./start.py --swarm --name=cs3 --version=7.0.2.348 --ip=192.168.1.3 --accept-eula=Yes
```
Remove a node from the cluster with:
```bash
docker swarm leave
```
Services can be scaled with:
```bash
docker service scale <service>=<N>
```

## GraphDB
For containers we use the standard GraphDB from https://hub.docker.com/r/ontotext/graphdb/ to get a license contact https://www.ontotext.com/.
For test you can run it without a license in free mode.
You need to have a free IP address in that subnet to set as a static address for your container.

If you use semantics, then you start GraphDB like this:
```
./start-graphdb 192.168.1.6
```
The IP is just an example.
When it has been started, access it at (for this example) http://192.168.1.6:7200.
Create a new GraphDB repository with id "nsp". Also choose to enable context index.
If you then start your ebo-enterprise-server or ebo-enterprise-central with:
```
--graphdb=http://192.168.1.6:7200
```
The server will connect to this instance and upload the ontologies to GrapDB.
You could also manually set the url in the servers Semantic settings and right click on semantics to upload the ontologies. When the ontologies are uploaded you need to relogin to WorkStation to enable the semantic functionality.

