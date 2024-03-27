#!/bin/bash
#
# Скрипт копирующий файлы/каталоги в chroot. Для удобства.
#
# 2023 (c) haegor
#

cp='sudo cp'

if [ -n "$1" ]
then
    if [ -f "$1" ] || [ -d "$1" ] || [ -L "$1" ]
    then
        obj2copy="$1"
    else
        echo "Указанный объект не существует."
        exit 0
    fi
else
    echo "Не указан объект для копирования"
    exit 0
fi

[ -n "$2" ] \
  && work_dir="$2" \
  || work_dir="./work_dir"

$cp --recursive --parents "$obj2copy" "$work_dir"
