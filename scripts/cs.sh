#!/bin/bash

mkdir -p ${HOME}/docker_cs && cd ${HOME}/docker_cs

git clone https://github.com/gnufanat/docker_cs . &&

IPH=$(ip -4 route get 1 | awk '{print $7; exit}') && grep -q '^SERVER_IP=' .env 2>/dev/null && sed -i "s/^SERVER_IP=.*/SERVER_IP=$IPH/" .env || echo "SERVER_IP=$IPH" >> .env && grep -q '^sv_downloadurl' server.cfg 2>/dev/null && sed -i "s|^sv_downloadurl.*|sv_downloadurl \"http://$IPH:8283/cstrike/\"|" server.cfg || echo "sv_downloadurl \"http://$IPH:8283/cstrike/\"" >> server.cfg && 

RCON=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24) && (grep -q '^rcon_password' server.cfg 2>/dev/null && sed -i "s|^rcon_password.*|rcon_password \"$RCON\"|" server.cfg || echo "rcon_password \"$RCON\"" >> server.cfg) && 

docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t cs:latest . &&

id=$(docker create cs:latest) && mkdir -p ./store && rm -rf ./store/* && docker cp $id:/home/hlds/store/cstrike/. ./store && docker rm $id &&

find ./store/maps -type f -name "*.bsp" -exec bash -c '[ ! -f "$1.bz2" ] && bzip2 -k "$1"; basename "$1" .bsp' _ {} \; > ./store/addons/amxmodx/configs/maps.ini && 

ipa=$(ip route get 1.1.1.1 | awk '{print $7; exit}'); grep -qxF "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" ./store/addons/amxmodx/configs/users.ini || echo "\"${ipa}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" >> ./store/addons/amxmodx/configs/users.ini && docker compose -p hlds up -d
