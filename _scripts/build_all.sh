#!/bin/bash
#
# Поочерёдно обходит все директории, запускает сборку образов и пушит в местный реджистри.
#
# 2023 (c) haegor
#

[ -f "./settings.sh" ] && . ./settings.sh

project_dir="$(pwd)"
subdirs=$(find "${project_dir}" -maxdepth 1 -type d)

for dir in ${subdirs}
do
    [ ! -d "${dir}/image" ] && continue

    echo "===== ${dir} ====="
    cd "${dir}"

    ${RUN} ./build.sh
    ${RUN} ./push.sh

    cd "${project_dir}"
done
