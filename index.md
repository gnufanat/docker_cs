## Сборка и установка docker-контейнера Counter-Strike 1.6

<div class="video">
  <iframe src="https://www.youtube.com/embed/5RH34ddWmwg"
    title="Docker_CS 1.6 сервер #1"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen>
  </iframe>
</div>

**Устанавливаемые компоненты**
```bash
rehlds-3.14.0.857
regamedll_cs-5.28.0.756
metamod-r 1.3.0.149
amxmodx-1.9.0
reunion-0.2.0.25
reapi-5.26.0.338
nginx_fastdl
```
**Рекомендуемые требования для VPS**  
**Виртуализация:** KVM  
**Дистрибутив:** Debian/Ubuntu  
**RAM:** 1ГБ  
**SSD:** 10ГБ

## Базовая настройка системы

**выполняем команды от пользователя root**  
или получаем права суперпользователя
```bash
sudo -i
```

**устанавливаем программы**
```bash
apt install mc git unzip micro -y
```

**устанавливаем docker**
```bash
curl -fsSL https://get.docker.com | sh
```

**создаём пользователя hlds (отвечаем на вопросы и задаём пароль пользователю)**
```bash
adduser hlds
```

**добавляем пользователя hlds в группу sudo и docker**
```bash
usermod -aG sudo,docker hlds
```

**переключаемся на пользователя hlds**   
далее выполняем команды от пользователя **hlds**
```bash
su - hlds
```

**создаём рабочий каталог и переходим в него**
```bash
mkdir -p ${HOME}/docker_cs && cd ${HOME}/docker_cs
```

**клонируем репозиторий docker_cs в текущий каталог**
```bash
git clone https://github.com/gnufanat/docker_cs .
```

## Настройка сервера

📝 Откройте файл: **.env**
```bash  
mcedit .env
```

**стандартный порт можно изменить на другой доступный порт**
```bash
SERVER_PORT=27015
```

**укажите ip-адрес сервера**
```bash
SERVER_IP=ip_адрес_сервера
```

Если нужно запустить сервер с **500FPS** вместо **1200FPS**
```bash
SYS_TICRATE=500
PING_BOOST=2
```
**укажите стартовую карту на сервере**
```bash
START_MAP=de_dust2
```

📝 Откройте файл: **server.cfg**
```bash  
mcedit server.cfg
```

**измените ip-адрес быстрой закачки (fastdl)**
```bash
sv_downloadurl "http://ip_адрес_сервера:8283/cstrike/"
```

**измените rcon-проль на свой**
```bash
rcon_password "надёжный_rcon_пароль"
```

📟 готовая команда для автоматической вставки ip-адреса сервера в файлах **.env** и **server.cfg**
```bash
IP=$(hostname -I | awk '{print $1}') && grep -q '^SERVER_IP=' .env 2>/dev/null && sed -i "s/^SERVER_IP=.*/SERVER_IP=$IP/" .env || echo "SERVER_IP=$IP" >> .env && grep -q '^sv_downloadurl' server.cfg 2>/dev/null && sed -i "s|^sv_downloadurl.*|sv_downloadurl \"http://$IP:8283/cstrike/\"|" server.cfg || echo "sv_downloadurl \"http://$IP:8283/cstrike/\"" >> server.cfg
```

📟 готовая команда для автоматической генерации и вставки rcon-пароля в **server.cfg**
```bash 
RCON=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24) && grep -q '^rcon_password' server.cfg 2>/dev/null && sed -i "s|^rcon_password.*|rcon_password \"$RCON\"|" server.cfg || echo "rcon_password \"$RCON\"" >> server.cfg
```

📝 Откройте файл: **compose.yml**
```bash  
mcedit compose.yml
```

**ядро и оперативная память**
```bash
cpuset: "0"
mem_limit: "512m"
```
**cpuset** - определяет на каком ядре будет работать сервер (привязка к ядру)  
**mem_limit** - определяет количество оперативной памяти которое доступно контейнеру, при превышении лимита - сервер будет перезагружен.

**настройка порта для быстрой закачки (fastdl)**
```bash
ports:
  - "8283:80"
```
**ports:** - внешний (8283) и внутренний порт контейнера (80)
 

## Создаём образ и контейнеры
                 
**Создаём образ с именем cs**
```bash
docker build --build-arg USER_UID=$(grep USER_UID .env | cut -d= -f2) --build-arg USER_GID=$(grep USER_GID .env | cut -d= -f2) -t cs:latest .
```

**Создаём и запускаем контейнер-донор**
```bash
docker run -d --name cs cs:latest
```

**Копируем файлы контейнера-донора на хостовую машину в каталог пользователя и останавливаем контейнер-донор**
```bash
mkdir -p ./store && rm -rf ./store/* && docker cp cs:/home/hlds/store/cstrike/. ./store && docker stop cs
```
❗файлы сервера в каталоге **./store** будут доступны всегда, даже после удаления контейнера❗

**Создать список карт на сервере**
```bash
find ./store/maps -type f -name "*.bsp" -exec bash -c '[ ! -f "$1.bz2" ] && bzip2 -k "$1"; basename "$1" .bsp' _ {} \; > ./store/addons/amxmodx/configs/maps.ini
```

**Добавить администратора по IP-адресу**
`ip="123.45.67.89 - заменить на нужный`
```bash
ip="123.45.67.89"; grep -qxF "\"${ip}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" ./store/addons/amxmodx/configs/users.ini || echo "\"${ip}\" \"\" \"abcdefghijklmnopqrstuv\" \"de\"" >> ./store/addons/amxmodx/configs/users.ini
```

**Добавить администратора по SteamID**
`steamid="STEAM_0:1:000000000" - заменить на нужный`
```bash
steamid="STEAM_0:1:000000000"; grep -qxF "\"$steamid\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" ./store/addons/amxmodx/configs/users.ini || echo "\"$steamid\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" >> ./store/addons/amxmodx/configs/users.ini
```

**Запускаем проект**
```bash
docker compose -p hlds up -d
```

## Полезные команды

**Поднятие контейнеров указанных в compose-файле** 
```bash
docker compose -p hlds up -d
```

**Остановит и удалит все контейнеры указанные в compose-файле** 
```bash
docker compose -p hlds down
```

**Перезапуск контейнеров указанных в compose-файле** 
```bash
docker compose -p hlds restart
```

**Пересборка образов с учётом изменений**
```bash
docker compose -p hlds build --no-cache
```

**Зайти во внутрь контейнера, позволяет работать в командной строке как в обычной Linux-системе**
```bash
docker exec -it hlds bash
```
```bash
docker exec -it fastdl bash
```

**Просмотр логов контейнера**
```bash
docker logs -f hlds
```

```bash
docker logs -f fastdl
```

**Запуск контейнера**
```bash
docker start hlds
```

```bash
docker start fastdl
```

**Остановка контейнера**
```bash
docker stop hlds
```

```bash
docker stop fastdl
```

**Перезапуск контейнера**
```bash
docker restart hlds
```

```bash
docker restart fastdl
```

## Удаление docker_cs

**Останавливает и удаляет проект, очищает все неиспользуемые ресурсы Docker**
```bash
docker compose -p hlds down && docker system prune -a --volumes -f
```

**Полностью удаляем docker**
```bash
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin docker-ce-rootless-extras && sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc && sudo rm -rf /var/lib/docker /var/lib/containerd && sudo apt autoremove -y && sudo groupdel docker && sudo apt update
```

**Удаление пользователя hlds**  
⏹️ завершаем сессию пользователя **hlds** и возвращаемся к **root**
```bash
exit
``` 
❌ удаляем пользователя **hlds**
```bash
userdel -r hlds
```
