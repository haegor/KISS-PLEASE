#!/bin/bash

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

docker-compose down

prev_image_id=$(${DKR} image list --format "table {{.ID}}\t{{.Repository}}" | grep "${IMAGE}" | cut -f1 -d' ')
./build.sh
new_image_id=$(${DKR} image list --format "table {{.ID}}\t{{.Repository}}" | grep "${IMAGE}" | cut -f1 -d' ')

#new_container_id=$(${dkr} container ls -l --format "table {{.ID}}" | grep -v CONTAINER)

if [ "${prev_image_id}" == "${new_image_id}" ];
then
  echo
  echo "Новый образ соответствует старому, удаление не требуется"
else
  echo
  echo "Новый образ: ${new_image_id}, старый образ (${prev_image_id}) - убираем"
  ${DKR} rmi ${prev_image_id}
fi

