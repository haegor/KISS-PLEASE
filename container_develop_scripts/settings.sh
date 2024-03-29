#!/bin/bash
#
# Данный скрипт предназначен для автозаполнения всех недостающих настроек.
# Само по себе это уже делает его самодостаточным и единственным необходимым
# для работы остальных скриптов.
# При этон он универсален и является единым файлом настроек. Поэтому, для его
# подкладыванеия в нужную папку, следует использовать мягкую ссылку.
#
# Именно он грузит файл индивидуальных настроек (individual_settings.sh) и
# интерпретирует указанные в нём значения.
#
# individual_settings.sh обязателен только для скриптов работы с образами.
# Минимально что в нём следует для них указать - это сам образ для работы.
#
# Если нужна гибкость, наглядность или просто хочется чтобы скрипт составил
# строку сам, то их можно указать по отдельности, в одноимённых переменных.
#
# Полная строка выглядит так: ОБРАЗ=REGISTRY:PORT/SERVICE:VERSION
#
# Для большинства сценариев использования могут быть опущены почти все части,
# кроме REGISTRY. Так что если нужно что-то простое или не хочется
# заморачиваться, то можно просто вписать все параметры одной сторокой через
# переменную REGISTRY и всё.
#
# Касаемо остальных частей:
# Следует сразу оговориться касаемо терминологии docker-а: она запутывает.
# В списке образов, в колонке REGISTRY, показываются значания по смыслу равные:
# REGISTRY:PORT/SERVICE, что в сущности указывает на IMAGEs внутри REGISTRY, а
# не на сами REGISTRY. При этом, в других местах, под IMAGE подразумеваются как
# SERVICE, так и вся строка целиком. Но это не одно и тоже, их следует
# различать. Хотя бы для написания скриптов. А также чтобы облегчить понимание.
# По этим причинам: строка целиком именуется мной как IMAGE, конкретный образ
# внутри REGISTRY как SERVICE, а вписывать одной строкой предлагается через
# REGISTRY.
#
# В строке выше, слово IMAGE было дано как его перевод ("ОБРАЗ") чтобы исключить
# ещё большее запутывание для тех кто недочитает объяснение.
#
# Почему именно SERVICE? Любая программа - это набор действий. Но когда они
# делаются для кого-то, то это уже услуга (SERVICE) и оказывает их обслуживающий
# (SERVER).
#
# С остальными частями проще.
# PORT - сам по себе не обязателен. По дефолту используется https.
# VERSION - по дефолту используется latest.
# SERVICE - это имя самого образа. Если нужно чтобы скрипт взял его из имени
# папки, то можно задать его как:
# SERVICE=$(basename "$(pwd)").
#
# Для CONTAINER скрипт сделает тоже самое и добавит к полученному '-tmp'.
#
# 2023-2024 (c) haegor
#

### Individual #################################################################
# Должен вызываться в самом начале т.к. всё остальное отталкивается от его
# содержимого
[ -f "./individual_settings.sh" ] && source "./individual_settings.sh"

### Run ########################################################################
# Всё что касается любых запусков

# Так везде будет вызываться docker
[ -n "${DKR}" ] || DKR="sudo docker"

# Команда для запуска kubectl
#[ -n "$kubectl" ] || kubectl='sudo k3s kubectl'
[ -n "$kubectl" ] || kubectl='kubectl'

# Команда для запуска crictl
[ -n "$crictl" ] || crictl='sudo k3s crictl'

# ${RUN} - команда для запуска скриптов на хост-машине
#
# Так удобнее отлаживать
#RUN="echo sudo bash"
#RUN="sudo +x bash"
#
# А так задействовать sudo
[ -n "$RUN" ] || RUN="sudo bash"

# ${RUN_COMMAND} - команда, запускаемая внутри конейнеров/подов.
# Используется, к примеру, в docker create. Выбран за универсальность.
[ -n "$RUN_COMMAND" ] || RUN_COMMAND="/bin/sh"

# Для запуска без параметров и смонтированных волюмов
[ -n "$RUN_ONCE" ] || RUN_ONCE=""

### Images #####################################################################
# Указание образов и всего что с ними связано
# TODO: нужен автосчётчик версий

[ -n "${namespace}" ] && namespace='default'

[ -n "${REGISTRY}" ]  && IMAGE="${REGISTRY}"
[ -n "${PORT}" ]      && IMAGE+=":${PORT}"
[ -n "${SERVICE}" ]   && IMAGE+="/${SERVICE}"
[ -n "${VERSION}" ]   && IMAGE+=":${VERSION}"

[ -n "${CONTAINER}" ] || CONTAINER=$(echo "$(basename $(pwd))-tmp")

# Такие манипуляции нужны для последующего использования в связве с sed
[ -n "${platform}" ] && platform=$(echo $platform | tr '/' '\/')

### Dirs #######################################################################
# Рабочие папки. Назначение дефолтов

[ -n "$extract_dir" ] || extract_dir='./extracted'
[ -n "$image_dir" ]   || image_dir='./image'
[ -n "$volume_dir" ]  || volume_dir='./volume'
[ -n "$certs_dir" ]   || certs_dir='./certs'
[ -n "$work_dir" ]    || work_dir="${image_dir}"

VOLUME_HOST="$(pwd)/${volume_dir}"
[ ! -d "${VOLUME_HOST}" ] && mkdir -p "${VOLUME_HOST}"

VOLUME_CONT="/mnt"

### Envs #######################################################################
# Переменные окружения

if [ -f "./env" ] || [ -L "./env" ]
then
    ENVFILE="--env-file ./env"
else
    ENVFILE=''
fi
