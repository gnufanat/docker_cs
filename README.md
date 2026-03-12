## Сборка и установка docker-контейнера Counter-Strike 1.6

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

**Выполняем команды от пользователя root!**
```bash
apt install mc git unzip -y
```

**Устанавливаем docker**
```bash
curl -fsSL https://get.docker.com | sh
```
**Автозагрузка docker**
```bash
systemctl enable --now docker
```

**Создаём пользователя hlds (отвечаем на вопросы и задаём пароль пользователю)**
```bash
adduser hlds
```

**Добавляем пользователя hlds в группу docker**
```bash
usermod -aG docker hlds
newgrp docker
```

**Переключаемся на пользователя hlds**
```bash
su - hlds
```

**Создаём рабочий каталог и переходим в него**
```bash
mkdir -p ${HOME}/docker_cs && cd ${HOME}/docker_cs
```

**Клонируем репозиторий docker_cs**
```bash
git clone https://github.com/gnufanat/docker_cs .
```

## Настройка сервера

**В данном примере, создадим сервер cs 1.6 работающий на порту 27015**

В файле: **.env**
```bash
SERVER_PORT=27015
```
**можно изменить на:**
```bash
SERVER_PORT=27016
```

**ОБЯЗАТЕЛЬНО! Укажите ip-адрес сервера!!!**
```bash
SERVER_IP=ip_адрес_вашего_сервера
```

Также измените адрес быстрой закачки (fastdl) в файле **server.cfg**
```bash
sv_downloadurl "http://ip_адрес_вашего_сервера:8283/cstrike/"
```

## Проверьте UID и GID текущего пользователя
**введите в терминале:**
```bash
id
```

**вывод должен быть таким:**
```bash
uid=1000(hlds) gid=1000(hlds)...
```

Если **UID** и **GID** имеют другое значение, то исправьте его в файле **.env**
```bash
USER_UID=UID_пользователя_hlds
USER_GID=GID_пользователя_hlds
```

## Создаём образ и контейнеры
                 
**Создаём образ с именем cs для контейнера-донора**
```bash
docker build -t cs:latest .
```

**Запускаем контейнер-донор**
```bash
docker run -d --name cs cs:latest
```

**Копируем файлы контейнера-донора на хостовую машину в каталог пользователя и останавливаем контейнер-донор**
```bash
mkdir -p ./store && rm -rf ./store/* && docker cp cs:/home/hlds/store/cstrike/. ./store && docker stop cs
```
теперь мы имеем файлы сервера которые будут доступны даже при удалении контейнера

**Запускаем сервис**
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

**Зайти во внутрь контейнера, позволяет работать в командной строке как в обычной Linux-системе**
```bash
docker exec -it hlds bash
```

**Просмотр логов контейнера**
```bash
docker logs -f hlds
```

**Запуск контейнера**
```bash
docker start hlds
```

**Остановка контейнера**
```bash
docker stop hlds
```

**Перезапуск контейнера**
```bash
docker restart hlds
```

**Пересборка образов с учётом изменений**
```bash
docker compose -p hlds build --no-cache
```

**Остановка контейнеров и полное их удаление вместе с образом**
```bash
docker compose -p hlds down && docker container prune -f && docker image prune -af && docker network prune -f && docker volume prune -f && docker builder prune -f
```
