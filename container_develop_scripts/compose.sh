#!/bin/bash
#
# По смыслу и строению этот скрипт повторяет deploy.sh, но предназначен для
# работы с docker-compose.
#
# 2024 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

if [ -n "$2" ]
then
  manifest="$2"
else
  our_subdir=$(basename $(pwd))
  manifest=$( find . -maxdepth 1 -type f \( -iname "*${our_subdir}*.yml" -or -iname "*${our_subdir}*.yaml" \) -not -iname "docker-compose.y*ml" -print -quit 2>/dev/null )

  [ -z "$manifest" ] \
    && manifest=$( find . -maxdepth 1 -type f -iname "docker-compose.y*ml" -print -quit 2>/dev/null )

  [ -z "$manifest" ] \
    && manifest=$( find . -maxdepth 1 -type f \( -iname "*.yml" -or -iname "*.yaml" \) -print -quit 2>/dev/null )

  [ -z "$manifest" ] && { echo "Манифест docker-compose.yml или его замена не задан и не может быть найден автоматически. Останов."; exit 1; }
fi

case $1 in
'reboot'|'restart'|'restart.sh')	# restart
  docker-compose down
  docker-compose up -d
;;
'run'|'start'|'start.sh')		# start
  docker-compose up -d
;;
'down'|'stop'|'stop.sh')		# stop
  docker-compose down
;;
'--help'|'-help'|'help'|'-h'|'*'|'')    # Автопомощь. Мы тут.
  echo
  echo "Недостаточно параметров. Всего нужно: 1"
  echo "Первый параметр - тип действия"
  echo "[Второй параметр] - файл манифеста"
  echo
  echo "Перечень доступных опций:"
  grep -P "^\'[[:graph:]]*\'\)[[:space:]]*#?.*$" $0 | grep -v 'excluder'
  echo
  exit 0
;;
esac
