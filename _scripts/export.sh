#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings

${DKR} export ${CONTAINER} --output ${CONTAINER}.tar
gzip ${CONTAINER}.tar
