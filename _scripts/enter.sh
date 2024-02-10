#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

${DKR} exec -it ${CONTAINER} "${RUN_COMMAND}"
