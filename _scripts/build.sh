#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

[ -f "./prepare.sh" ] || [ -L "./prepare.sh" ] && ${RUN} "./prepare.sh"

${DKR} build --file ./Dockerfile "${image_dir}" -t "${IMAGE}"
