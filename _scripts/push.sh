#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

[ "${IMAGE:0:5}" == 'https' ] \
  && ${DKR} push "${IMAGE}" \
  || ${DKR} push --disable-content-trust "${IMAGE}"


