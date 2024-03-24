#!/bin/bash
#
# Создаёт правильные ссылки на скрипты из вышестоящей директории.
# Правильные ссылки являются битыми пока они лежат в этой директории и обретают
# изначальный смысл как только копируются в субдиректорию, в которой ведётся
# работа с образом.
#

find "../../" -maxdepth 1 -type f -iname "*.sh" ! -iname "docker-entrypoint.sh" ! -iname "*-all.sh" ! -iname "*-old.sh" -exec \
  bash -c "echo {} | sed 's=../../==' | xargs --no-run-if-empty -I'}{' ln -s '../_scripts/}{' './}{' && echo Ссылка на {} создана" \;


