#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

./rm.sh

${DKR} run -itd \
    --name ${CONTAINER} \
    "${IMAGE}" \
    "${RUN_ONCE}"
