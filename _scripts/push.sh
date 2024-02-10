#!/bin/bash
#
# 2023 (c) haegor
#

. ./settings.sh

${DKR} push --disable-content-trust "${IMAGE}"
