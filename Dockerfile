FROM debian:bookworm-slim

# Мета
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.vcs-ref=${VCS_REF}

# Аргументы
ARG SERVER_NAME="Counter-Strike 1.6"
ARG STEAM_LOGIN="anonymous"
ARG STEAM_PASSWORD=""
ARG ADMIN_STEAM_ID="STEAM_0:1:000000000"
ARG USER_UID=1000
ARG USER_GID=1000
ARG STEAM_CMD="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
ARG REHLDS_URL="https://github.com/rehlds/ReHLDS/releases/download/3.14.0.857/rehlds-bin-3.14.0.857.zip"
ARG METAMOD_R="https://github.com/rehlds/Metamod-R/releases/download/1.3.0.149/metamod-bin-1.3.0.149.zip"
ARG AMXX_BASE="https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5294-base-linux.tar.gz"
ARG REAPI_URL="https://github.com/rehlds/ReAPI/releases/download/5.26.0.338/reapi-bin-5.26.0.338.zip"
ARG REUNION_URL="https://github.com/rehlds/ReUnion/releases/download/0.2.0.34/reunion-0.2.0.34.zip"
ARG REGAMEDLL_URL="https://github.com/rehlds/ReGameDLL_CS/releases/download/5.28.0.756/regamedll-bin-5.28.0.756.zip"

# Переменные
ENV PING_BOOST="3"
ENV SYS_TICRATE="1200"
ENV MAX_PLAYERS="32"

# Зависимости
RUN groupadd -g ${USER_GID} hlds && \
    useradd -u ${USER_UID} -g ${USER_GID} -ms /bin/bash hlds && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -qqy install \
        libc6:i386 lib32gcc-s1 lib32stdc++6 lib32z1 \
        lib32tinfo6 lib32ncurses6 \
        libsdl2-2.0-0:i386 libcurl4:i386 libssl3:i386 \
        curl unzip mc && \
    rm -rf /var/lib/apt/lists/*

USER hlds
WORKDIR /home/hlds/store

# HLDS
RUN mkdir -p /home/hlds/store /home/hlds/Steam /home/hlds/.steam/sdk32 && \
    curl -sqL "${STEAM_CMD}" | tar zxf - -C /home/hlds/Steam && \
    /home/hlds/Steam/steamcmd.sh +login ${STEAM_LOGIN} ${STEAM_PASSWORD} \
        +force_install_dir "/home/hlds/store" \
        +app_set_config 90 mod cstrike \
        +app_update 90 -beta steam_legacy validate +quit && \
    cp -f /home/hlds/Steam/linux32/steamclient.so /home/hlds/.steam/sdk32/ && \
    rm -rf /home/hlds/Steam && \
    touch /home/hlds/store/cstrike/listip.cfg /home/hlds/store/cstrike/banned.cfg && \
    chmod 500 /home/hlds/store/hlds_run && \
    chmod 600 /home/hlds/store/cstrike/listip.cfg /home/hlds/store/cstrike/banned.cfg

# ReHLDS
RUN curl -L -o /tmp/rehlds.zip ${REHLDS_URL} && \
    unzip -q /tmp/rehlds.zip -d /tmp/rehlds && \
    cp -rf /tmp/rehlds/bin/linux32/* /home/hlds/store/ && \
    rm -rf /tmp/rehlds /tmp/rehlds.zip && \
    chmod +x /home/hlds/store/hlds_run /home/hlds/store/hlds_linux /home/hlds/store/engine_i486.so && \
    rm -rf /home/hlds/store/bin/win32 /home/hlds/store/hlsdk

# Metamod-r
RUN curl -sL "${METAMOD_R}" -o /tmp/metamod.zip && \
    unzip -q /tmp/metamod.zip -d /tmp/metamod && \
    mkdir -p /home/hlds/store/cstrike/addons/metamod && \
    cp /tmp/metamod/addons/metamod/metamod_i386.so /home/hlds/store/cstrike/addons/metamod/ && \
    cp /tmp/metamod/addons/metamod/config.ini /home/hlds/store/cstrike/addons/metamod/ && \
    rm -rf /tmp/metamod /tmp/metamod.zip && \
    sed -i 's~gamedll_linux "dlls/cs.so"~#gamedll_linux "dlls/cs.so"\ngamedll_linux "addons/metamod/metamod_i386.so"~' /home/hlds/store/cstrike/liblist.gam

# AMXModX
RUN curl -sL "${AMXX_BASE}" | tar -xzf - -C /home/hlds/store/cstrike && \
    echo "\"${ADMIN_STEAM_ID}\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" >> /home/hlds/store/cstrike/addons/amxmodx/configs/users.ini

# ReAPI
RUN curl -L -o /tmp/reapi.zip ${REAPI_URL} && \
    unzip -q /tmp/reapi.zip -d /tmp/reapi && \
    cp /tmp/reapi/addons/amxmodx/modules/reapi_amxx_i386.so \
       /home/hlds/store/cstrike/addons/amxmodx/modules/ && \
    rm -rf /tmp/reapi /tmp/reapi.zip && \
    echo "reapi_amxx_i386" >> /home/hlds/store/cstrike/addons/amxmodx/configs/modules.ini

# ReUnion
RUN curl -L -o /tmp/reunion.zip ${REUNION_URL} && \
    unzip -q /tmp/reunion.zip -d /tmp/reunion && \
    mkdir -p /home/hlds/store/cstrike/addons/reunion && \
    find /tmp/reunion -type f -name "reunion_mm_i386.so" -exec cp {} /home/hlds/store/cstrike/addons/reunion/ \; && \
    find /tmp/reunion -type f -name "reunion.cfg" -exec cp {} /home/hlds/store/cstrike/reunion.cfg \; && \
    HASH=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32) && \
    sed -i "s~^SteamIdHashSalt\s*=.*~SteamIdHashSalt = ${HASH}~" /home/hlds/store/cstrike/reunion.cfg && \
    rm -rf /tmp/reunion /tmp/reunion.zip

# ReGameDLL_CS
RUN curl -L -o /tmp/regamedll.zip ${REGAMEDLL_URL} && \
    unzip -q /tmp/regamedll.zip -d /tmp/regamedll && \
    cp -rf /tmp/regamedll/bin/linux32/cstrike/* /home/hlds/store/cstrike/ && \
    rm -rf /tmp/regamedll /tmp/regamedll.zip

# Metamod plugins
RUN printf "linux addons/reunion/reunion_mm_i386.so\nlinux addons/amxmodx/dlls/amxmodx_mm_i386.so\n" \
> /home/hlds/store/cstrike/addons/metamod/plugins.ini

USER root
# Очистка от мусора
RUN apt-get remove -y curl unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER hlds
ENTRYPOINT /home/hlds/store/hlds_run -pingboost ${PING_BOOST} -game cstrike +ip ${SERVER_IP} -port ${SERVER_PORT} +sys_ticrate ${SYS_TICRATE} +sv_lan ${SV_LAN} +log on +mp_logecho 1 +clientport ${CLIENT_PORT} +map ${START_MAP} -maxplayers ${MAX_PLAYERS}
