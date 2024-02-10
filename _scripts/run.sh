#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

./rm.sh

${DKR} run -itd \
	--name ${CONTAINER} \
        --volume="${VOLUME_HOST}:${VOLUME_CONT}" \
	${ENVFILE} \
	"${IMAGE}"
