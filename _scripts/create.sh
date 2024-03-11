#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

${DKR} create -it \
  --name="${CONTAINER}" \
  --volume="${VOLUME_HOST}:${VOLUME_CONT}" \
  ${ENVFILE} \
  "${IMAGE}" \
  "${RUN_COMMAND}"

