#!/bin/bash
#
# Единый файл настроек для всех скриптов. Для его использования в папке должна
# быть ссылка на этот файл (settings.sh).
#
# Все дополнительные опции указываются через ./settings_individual.sh
# Минимально в нём следует указать образ для работы.
# Полная строка выглядит так: IMAGE=REGISTRY:PORT/SERVICE:VERSION
#
# Если не хочется заморачиваться, то можно указать только переменнную REGISTRY, а
# все остальные части задать прямо в ней.
# Если хочется чтобы скрипт составил её из составных частей, то их можно указать
# по отдельности. При этом могут быть опущены все части, кроме REGISTRY.
#
# Если не указать VERSION, то docker сам подставит latest.
# Если нужно взять SERVICE из имени папки, то укажите его как:
# SERVICE="$(basename $(pwd))"
# Для CONTAINER скрипт сделает тоже самое, но добавит '-tmp'
#

### Individual #################################################################
# Должен быть в самом начале т.к. всё остальное отталкивается от его содержимого
[ -f "./individual_settings.sh" ] && . "./individual_settings.sh"

### Run ########################################################################
# Всё что касается любых запусков

# Так везде будет вызываться docker
[ -n "${DKR}" ] || DKR="sudo docker"

# Команда для запуска kubectl
[ -n "$kubectl" ] || kubectl='sudo k3s kubectl'

# Команда для запуска crictl
[ -n "$crictl" ] || crictl='sudo k3s crictl'

# ${RUN} - команда для запуска комманд на хост-машине
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

[ -n "${namespace}" ] && namespace='default'

[ -n "${REGISTRY}" ] && IMAGE=${REGISTRY}

[ -n "${PORT}" ] && IMAGE="${IMAGE}:${PORT}"

[ -n "${SERVICE}" ] && IMAGE="${IMAGE}/${SERVICE}"

[ -n "${VERSION}" ] && IMAGE="${IMAGE}:${VERSION}"

[ -n "${CONTAINER}" ] || CONTAINER=$(echo "$(basename $(pwd))-tmp")

### Dirs #######################################################################
# Рабочие папки

[ -n "$extract_dir" ] || extract_dir='./extracted'
[ -n "$image_dir" ]   || image_dir='./image'
[ -n "$volume_dir" ]  || volume_dir='volume'
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
