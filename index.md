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

**Выполняем команды от пользователя root**
```bash
apt install mc git unzip -y
```

**Устанавливаем docker**
```bash
curl -fsSL https://get.docker.com | sh
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

далее выполняем команды от пользователя **hlds**
```bash
su - hlds
```

**Создаём рабочий каталог и переходим в него**
```bash
mkdir -p ${HOME}/docker_cs && cd ${HOME}/docker_cs
```

**Клонируем репозиторий docker_cs в текущий каталог**
```bash
git clone https://github.com/gnufanat/docker_cs .
```

## Настройка сервера

**В данном примере, создадим сервер cs 1.6 работающий на порту 27015**

В файле: **.env**
```bash
SERVER_PORT=27015
```
**можно изменить на другой доступный порт:**
```bash
SERVER_PORT=27016
```

**ОБЯЗАТЕЛЬНО! Укажите ip-адрес сервера!!!**
```bash
SERVER_IP=ip_адрес_вашего_сервера
```

Также измените адрес быстрой закачки (fastdl) в файле **server.cfg**  
Рабочим считается файл **server.cfg** который лежит в корне проекта, там где файл **compose.yml**.  
**server.cfg** в каталоге **./store** не выполняет никаких функций.
```bash
sv_downloadurl "http://ip_адрес_вашего_сервера:8283/cstrike/"
```

Если нужно запустить сервер с **500FPS** вместо **1200FPS**  
Достаточно в файле **.env** указать эти значения:
```bash
SYS_TICRATE=500
PING_BOOST=2
```

В файле **compose.yml** есть следующие строки:
```bash
cpuset: "0"
mem_limit: "512m"
```

**cpuset** - определяет на каком ядре будет работать сервер (привязка к ядру)  
**mem_limit** - определяет количество оперативной памяти которое доступно контейнеру, при превышении лимита - сервер будет перезагружен.  

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

**Создаём и запускаем контейнер-донор**
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

**Остановка контейнеров и полное их удаление вместе с образом**
```bash
docker compose -p hlds down && docker container prune -f && docker image prune -af && docker network prune -f && docker volume prune -f && docker builder prune -f
```
