#!/bin/bash
#
# Данный же скрипт предназначен для автозаполнения всех недостающих настроек.
# Само по себе это уже делает его самодостаточным и единственным необходимым
# для работы остальных скриптов.
# При этон он универсален и является единым файлом настроек. Поэтому, для его
# подкладыванеия в нужную папку, следует использовать мягкую ссылку.
#
# Именно он грузит файл индивидуальных настроек (settings_individual.sh) и
# интерпретирует указанные в нём значения.
#
# settings_individual.sh обязателен только для скриптов работы с образами.
# Минимально что в нём следует для них указать - это сам образ для работы.
# Полная строка выглядит так: ОБРАЗ=REGISTRY:PORT/SERVICE:VERSION
# Если нужна гибкость, наглядность или просто хочется чтобы скрипт составил
# строку сам, то их можно указать по отдельности, в одноимённых переменных.
# При этом могут быть опущены все части, кроме REGISTRY.
# PORT сам по себе не обязателен
# VERSION docker сам подставит как latest.
# SERVICE - это имя самого образа. Если нужно чтобы он взял его из имени папки,
# то можно задать его как: SERVICE="$(basename $(pwd))"
# Если не хочется заморачиваться, то можно просто всё вписать в REGISTRY.
#
# Для CONTAINER скрипт возьмёт имя текущей папки и добавит к нему '-tmp'
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
