#!/bin/bash
#
# docker_cs installer
# Automates: dependency checks/install (Docker, Docker Compose),
# docker group membership, repository setup, config generation,
# image build and container startup.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[ OK ]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[FAIL]${NC}    $*" >&2; }
step()    { echo -e "\n${BOLD}==> $*${NC}"; }

# ---------------------------------------------------------------------------
# 1. Root check — this script must NOT be run as root
# ---------------------------------------------------------------------------
step "Checking current user"
if [ "$(id -u)" -eq 0 ]; then
    error "This script must NOT be run as root (or with sudo)."
    error "Please run it as a regular user. It will use sudo internally when needed."
    exit 1
fi
success "Running as user: $(whoami)"

# ---------------------------------------------------------------------------
# 2. Detect distribution (for Docker installation)
# ---------------------------------------------------------------------------
step "Detecting Linux distribution"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_ID_LIKE="${ID_LIKE:-}"
else
    error "Cannot detect distribution: /etc/os-release not found."
    exit 1
fi
info "Detected distribution: ${DISTRO_ID} (${DISTRO_ID_LIKE:-n/a})"

# ---------------------------------------------------------------------------
# 3. Install Docker if missing
# ---------------------------------------------------------------------------
install_docker() {
    step "Installing Docker"
    case "$DISTRO_ID" in
        ubuntu|debian)
            info "Installing Docker for Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" | \
                sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            ARCH=$(dpkg --print-architecture)
            CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
            echo \
                "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        arch)
            info "Installing Docker for Arch Linux..."
            sudo pacman -Sy --noconfirm docker docker-compose docker-buildx
            ;;
        *)
            # Fallback for Debian/Ubuntu derivatives via ID_LIKE
            if [[ "$DISTRO_ID_LIKE" == *"debian"* ]]; then
                warn "Distribution '${DISTRO_ID}' is Debian-based, using Debian install steps."
                DISTRO_ID="debian"
                install_docker
                return
            elif [[ "$DISTRO_ID_LIKE" == *"arch"* ]]; then
                warn "Distribution '${DISTRO_ID}' is Arch-based, using Arch install steps."
                sudo pacman -Sy --noconfirm docker docker-compose docker-buildx
            else
                error "Unsupported distribution: ${DISTRO_ID}. Please install Docker manually."
                exit 1
            fi
            ;;
    esac

    info "Enabling and starting Docker service..."
    sudo systemctl enable --now docker
    success "Docker installed successfully."
}

step "Checking Docker installation"
if command -v docker >/dev/null 2>&1; then
    success "Docker is already installed ($(docker --version))."
else
    warn "Docker not found."
    install_docker
fi

# ---------------------------------------------------------------------------
# 4. Check Docker Compose (plugin) availability
# ---------------------------------------------------------------------------
step "Checking Docker Compose"
if docker compose version >/dev/null 2>&1; then
    success "Docker Compose is available ($(docker compose version --short 2>/dev/null || echo 'plugin'))."
else
    warn "Docker Compose plugin not found, attempting installation."
    case "$DISTRO_ID" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y docker-compose-plugin
            ;;
        arch)
            sudo pacman -Sy --noconfirm docker-compose
            ;;
        *)
            error "Could not install Docker Compose automatically for '${DISTRO_ID}'. Please install it manually."
            exit 1
            ;;
    esac
    if docker compose version >/dev/null 2>&1; then
        success "Docker Compose installed successfully."
    else
        error "Docker Compose installation failed."
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 5. Ensure Docker daemon is running
# ---------------------------------------------------------------------------
step "Checking Docker daemon status"
if ! sudo systemctl is-active --quiet docker; then
    warn "Docker daemon is not running, starting it now..."
    sudo systemctl enable --now docker
fi
success "Docker daemon is running."

# ---------------------------------------------------------------------------
# 6. Ensure current user is in the 'docker' group
# ---------------------------------------------------------------------------
step "Checking docker group membership"
if id -nG "$(whoami)" | grep -qw docker; then
    success "User '$(whoami)' is already a member of the 'docker' group."
else
    warn "User '$(whoami)' is NOT in the 'docker' group. Adding now..."
    sudo usermod -aG docker "$(whoami)"
    success "User added to 'docker' group."
    info "Applying new group membership to the current session (no logout required)..."
    # Re-exec the rest of this script under a shell that has the new group,
    # so the user doesn't need to log out/in for 'docker' commands to work.
    exec sg docker "$0" "$@"
fi

# ---------------------------------------------------------------------------
# 7. Verify docker access works without sudo
# ---------------------------------------------------------------------------
step "Verifying Docker access"
if docker info >/dev/null 2>&1; then
    success "Docker is accessible without sudo."
else
    error "Docker is still not accessible for the current user/session."
    error "Try running: newgrp docker   (or log out and back in), then re-run this script."
    exit 1
fi

# ---------------------------------------------------------------------------
# 8. Prepare working directory
# ---------------------------------------------------------------------------
step "Preparing working directory"
TARGET_DIR="${PWD}/docker_cs"

if [ -d "$TARGET_DIR" ]; then
    if [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        warn "Directory '${TARGET_DIR}' already exists and is not empty."
        read -rp "Do you want to continue and reuse it? [y/N]: " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            error "Aborted by user."
            exit 1
        fi
    else
        info "Directory '${TARGET_DIR}' exists and is empty, continuing."
    fi
else
    mkdir -p "$TARGET_DIR"
    success "Created directory: ${TARGET_DIR}"
fi

cd "$TARGET_DIR"
info "Working directory: $(pwd)"

# ---------------------------------------------------------------------------
# 9. Clone repository, configure and build (original working logic, unchanged)
# ---------------------------------------------------------------------------
step "Cloning repository and building the server"

git clone https://github.com/gnufanat/docker_cs . &&
IPH=$(ip -4 route get 1 | awk '{print $7; exit}') && grep -q '^SERVER_IP=' .env 2>/dev/null && sed -i "s/^SERVER_IP=.*/SERVER_IP=$IPH/" .env || echo "SERVER_IP=$IPH" >> .env && grep -q '^sv_downloadurl' server.cfg 2>/dev/null && sed -i "s|^sv_downloadurl.*|sv_downloadurl \"http://$IPH:8283/cstrike/\"|" server.cfg || echo "sv_downloadurl \"http://$IPH:8283/cstrike/\"" >> server.cfg &&
RCON=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24) && (grep -q '^rcon_password' server.cfg 2>/dev/null && sed -i "s|^rcon_password.*|rcon_password \"$RCON\"|" server.cfg || echo "rcon_password \"$RCON\"" >> server.cfg) &&
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t cs:latest . &&
id=$(docker create cs:latest) && mkdir -p ./store && rm -rf ./store/* && docker cp $id:/home/hlds/store/cstrike/. ./store && docker rm $id &&
find ./store/maps -type f -name "*.bsp" -exec bash -c '[ ! -f "$1.bz2" ] && bzip2 -k "$1"; basename "$1" .bsp' _ {} \; > ./store/addons/amxmodx/configs/maps.ini &&
ipa=$(ip route get 1.1.1.1 | awk '{print $7; exit}'); grep -qxF "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" ./store/addons/amxmodx/configs/users.ini || echo "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" >> ./store/addons/amxmodx/configs/users.ini && docker compose -p hlds up -d

# ---------------------------------------------------------------------------
# 10. Final status
# ---------------------------------------------------------------------------
if [ $? -eq 0 ]; then
    step "Installation complete"
    success "docker_cs server is up and running."
    info "Server IP:      ${IPH}"
    info "RCON password:  ${RCON}"
    info "Directory:      ${TARGET_DIR}"
else
    error "Something went wrong during build/startup. Check the output above."
    exit 1
fi
