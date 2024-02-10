#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

${DKR} create -it \
  --name="${CONTAINER}" \
  --volume="${VOLUME_HOST}:${VOLUME_CONT}" \
  ${ENVFILE} \
  "${IMAGE}" \
  "${RUN_COMMAND}"

