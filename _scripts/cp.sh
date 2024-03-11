#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

if [ "$1" ]
then
    copied_file="$1"
else
    echo "Не указан файл для копирования"
    exit 0
fi

[ -f "${extract_dir}" ] || mkdir -p "${extract_dir}"

bn="$(basename ${copied_file})"

${DKR} cp "${CONTAINER}:${copied_file}" "${extract_dir}/${bn}"
