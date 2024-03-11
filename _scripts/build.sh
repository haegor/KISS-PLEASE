#!/bin/bash
#
# 2023-2024 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

( [ -f "./prepare.sh" ] || [ -L "./prepare.sh" ] ) && ${RUN} "./prepare.sh"

if [ -n "$platform" ]
then
  echo "-------------------------------------------------------------------------------------"
  echo "Контейнер собирается на системе и при вызове команды RUN будет исполняться на ней же."
  echo "Иначе говоря: выполнять надо на ЦЕЛЕВОЙ платформе."
  echo "-------------------------------------------------------------------------------------"

  if [ ! -f "${image_dir}/Dockerfile" ]
  then
    sed "s={{ PLATFORM_NAME }}=${platform}=" "${image_dir}/Dockerfile-platform" > "${image_dir}/Dockerfile"
  fi

  # ${DKR} build --file "${image_dir}/Dockerfile" "${image_dir}" -t "${IMAGE}"
else
  cp "${image_dir}/Dockerfile-default" "${image_dir}/Dockerfile"
fi

${DKR} build "${image_dir}" -t "${IMAGE}"
