## 🐳 Building and Installing the Counter-Strike 1.6 Docker Container

![Linux](https://img.shields.io/badge/Linux-supported-FCC624?logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/github/license/gnufanat/docker_cs)
![Last commit](https://img.shields.io/github/last-commit/gnufanat/docker_cs)
![Repo size](https://img.shields.io/github/repo-size/gnufanat/docker_cs)

### 📦 Installed components

```bash
rehlds-3.14.0.857
regamedll_cs-5.28.0.756
metamod-r 1.3.0.149
amxmodx-1.9.0
reunion-0.2.0.25
reapi-5.26.0.338
nginx_fastdl
```

### 💻 Recommended VPS requirements

| Parameter | Value |
|---|---|
| Virtualization | KVM |
| RAM | 1 GB |
| SSD | 10 GB |
| Open ports | 27015/udp, 8283/tcp |

---

## ⚙️ Installing dependencies

Before setting up the server, install the packages used during deployment and container administration.

### Debian / Ubuntu

```bash
sudo apt update && apt install mc git unzip openssl micro -y
```

### Arch Linux

```bash
sudo pacman -S --needed --noconfirm mc git unzip openssl micro
```

---

## 🚀 Server setup

The server is installed with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/gnufanat/docker_cs/main/scripts/cs.sh | bash
```

---

## 🛠️ Useful commands

### Starting and stopping the project

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

### Working with containers

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
