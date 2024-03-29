#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

if [ $(${DKR} ps -q --filter name=${CONTAINER}) ]
then
  echo "Останов: $(${DKR} stop ${CONTAINER})"
fi

if [ $(${DKR} ps -aq --filter name=${CONTAINER}) ]
then
  echo "Удаление контейнера: $(${DKR} rm ${CONTAINER})"
fi
