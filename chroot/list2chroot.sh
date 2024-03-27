#!/bin/bash
#
# Создаёт chroot на базе указанного списка пакетов. Файлы для этого
# берутся из самой системы.
#
# 2023 (c) haegor
#

[ -f "./settings.sh" ] && . ./settings.sh

pkg2chroot='./pkg2chroot.sh'

if [ -z "$1" ] && [ -z "${work_dir}" ]
then
  work_dir='/mnt/dev'		# default
elif [ -n "$1" ]
then
  work_dir="$1"			# Приоритет у параметра командной строки
fi

pkgs=`cat ./packets | grep -vP '^#' | grep -v '^[[:space:]]*$'`

while read LINE
do
  echo "===== Installing packet $LINE =========================================="
  $pkg2chroot "${LINE}" "${work_dir}"

done < <(echo "${pkgs}")
