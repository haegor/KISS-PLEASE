#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

${DKR} start ${CONTAINER}
