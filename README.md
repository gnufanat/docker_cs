## 🐳 Building and Installing the Counter-Strike 1.6 Docker Container

![Linux](https://img.shields.io/badge/Linux-supported-FCC624?logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/github/license/gnufanat/docker_cs)
![Last commit](https://img.shields.io/github/last-commit/gnufanat/docker_cs)
![Repo size](https://img.shields.io/github/repo-size/gnufanat/docker_cs)

**Installed components**
```bash
rehlds-3.14.0.857
regamedll_cs-5.28.0.756
metamod-r 1.3.0.149
amxmodx-1.9.0
reunion-0.2.0.25
reapi-5.26.0.338
nginx_fastdl
```

**Recommended VPS requirements**  
**Virtualization:** KVM  
**Distribution:** Debian/Ubuntu  
**RAM:** 1 GB  
**SSD:** 10 GB  
**Open ports:** 27015/udp, 8283/tcp

## Basic system setup
**Run commands as root**  
or obtain superuser privileges
```bash
sudo -i
```

**Install required packages**
```bash
apt update && apt install mc git unzip openssl micro -y
```

**Install Docker**
```bash
curl -fsSL https://get.docker.com | sh
```

**Create the hlds user (answer prompts and set a password)**
```bash
adduser hlds
```

**Add hlds to sudo and docker groups**
```bash
usermod -aG sudo,docker hlds
```

**Switch to the hlds user**   
From this point, run commands as **hlds**
```bash
su - hlds
```

**Create the working directory and navigate into it**
```bash
mkdir -p ${HOME}/docker_cs && cd ${HOME}/docker_cs
```

**Clone the docker_cs repository into the current directory**
```bash
git clone https://github.com/gnufanat/docker_cs .
```

## Server configuration

📝 Open the file: **.env**
```bash
nano .env
```

**The default port can be changed to another available port**
```bash
SERVER_PORT=27015
```

**Set the server IP address**
```bash
SERVER_IP=server_ip_address
```

If you want to run the server at **500FPS** instead of **1200FPS**
```bash
SYS_TICRATE=500
PING_BOOST=2
```

**Set the maximum number of players**
```bash
MAX_PLAYERS=32
```

**Set the starting map**
```bash
START_MAP=de_dust2
```

📝 Open the file: **server.cfg**
```bash
nano server.cfg
```

**Change the fastdl URL**
```bash
sv_downloadurl "http://server_ip_address:8283/cstrike/"
```

**Change the rcon password to your own**
```bash
rcon_password "strong_rcon_password"
```

📟 Ready-made command to automatically insert the server IP address into **.env** and **server.cfg**
```bash
IPH=$(ip -4 route get 1 | awk '{print $7; exit}') && grep -q '^SERVER_IP=' .env 2>/dev/null && sed -i "s/^SERVER_IP=.*/SERVER_IP=$IPH/" .env || echo "SERVER_IP=$IPH" >> .env && grep -q '^sv_downloadurl' server.cfg 2>/dev/null && sed -i "s|^sv_downloadurl.*|sv_downloadurl \"http://$IPH:8283/cstrike/\"|" server.cfg || echo "sv_downloadurl \"http://$IPH:8283/cstrike/\"" >> server.cfg
```

📟 Ready-made command to generate and insert an rcon password into **server.cfg**
```bash
RCON=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24) && (grep -q '^rcon_password' server.cfg 2>/dev/null && sed -i "s|^rcon_password.*|rcon_password \"$RCON\"|" server.cfg || echo "rcon_password \"$RCON\"" >> server.cfg)
```

📝 Open the file: **compose.yml**
```bash
nano compose.yml
```

**CPU core and memory limits**
```bash
cpuset: "0"
mem_limit: "512m"
```
**cpuset** - defines which CPU core the server will use  
**mem_limit** - defines how much RAM is available to the container; if exceeded, the server will restart.

**FastDL port configuration**
```bash
ports:
  - "8283:80"
```
**ports:** - external port (8283) and internal container port (80)

## Build image and containers

**Create the image named cs**
```bash
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t cs:latest .
```

**Create a donor container, copy files to the host, remove the donor container**
```bash
id=$(docker create cs:latest) && mkdir -p ./store && rm -rf ./store/* && docker cp $id:/home/hlds/store/cstrike/. ./store && docker rm $id
```
❗The server files in **./store** will remain accessible even after the container is removed❗

**Create the server map list**
```bash
find ./store/maps -type f -name "*.bsp" -exec bash -c '[ ! -f "$1.bz2" ] && bzip2 -k "$1"; basename "$1" .bsp' _ {} \; > ./store/addons/amxmodx/configs/maps.ini
```

**Add an admin by IP address**
```bash
ipa=$(ip route get 1.1.1.1 | awk '{print $7; exit}'); grep -qxF "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" ./store/addons/amxmodx/configs/users.ini || echo "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" >> ./store/addons/amxmodx/configs/users.ini
```

**Add an admin by SteamID**
`steamid="STEAM_0:1:000000000" - replace with the correct value`
```bash
steamid="STEAM_0:1:000000000"; grep -qxF "\"$steamid\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" ./store/addons/amxmodx/configs/users.ini || echo "\"$steamid\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" >> ./store/addons/amxmodx/configs/users.ini
```

**Start the project**
```bash
docker compose -p hlds up -d
```

## Useful commands

**Start the project**
```bash
docker compose -p hlds up -d
```

**Stop the project**
```bash
docker compose -p hlds down
```

**Restart the project**
```bash
docker compose -p hlds restart
```

**Rebuild the project to apply changes**

```bash
docker compose -p hlds build --no-cache
```

**Container shell interface for working inside the container**
```bash
docker exec -it hlds bash
```

```bash
docker exec -it fastdl bash
```

**View container logs**
```bash
docker logs -f hlds
```

```bash
docker logs -f fastdl
```

**Start the container**
```bash
docker start hlds
```

```bash
docker start fastdl
```

**Stop the container**
```bash
docker stop hlds
```

```bash
docker stop fastdl
```

**Restart the container**
```bash
docker restart hlds
```

```bash
docker restart fastdl
```

## Removing docker_cs

**Stop and remove the Docker project, clean up all unused resources**  
Run this command as the **hlds** user
```bash
cd ~/docker_cs && docker compose -p hlds down && docker system prune -a --volumes -f
```

**Run commands as root**  
or obtain superuser privileges
```bash
sudo -i
```

**Completely remove Docker**
```bash
apt purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin docker-ce-rootless-extras && rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc && rm -rf /var/lib/docker /var/lib/containerd && apt autoremove -y && groupdel docker && apt update
```


**Remove the hlds user**
```bash
userdel -r hlds
```
