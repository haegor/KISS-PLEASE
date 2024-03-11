#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

./rm.sh

${DKR} run -itd \
    --name ${CONTAINER} \
    "${IMAGE}" \
    "${RUN_ONCE}"
