#!/bin/bash
#
# 2023 (c) haegor
#

source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

./rm.sh

prev_image_id=$(${DKR} image list --format "table {{.ID}}\t{{.Repository}}" | grep "${IMAGE}" | cut -f1 -d' ')
echo "===== Prev Image is ${prev_image_id} ================================"
echo "delete it!"
${DKR} rmi ${prev_image_id}

echo "===== Making new image =========================================="
./build.sh

new_image_id=$(${DKR} image list --format "table {{.ID}}\t{{.Repository}}" | grep "${IMAGE}" | cut -f1 -d' ')

if [ "${prev_image_id}" == "" ]
then
  echo "===== Ранее не было других образов. Выход."
  exit 0
fi

if [ "${new_image_id}" == "" ]
then
  echo "===== Нового образа не было создано. Выход. ====================="
  exit 0
fi

if [ "${prev_image_id}" == "${new_image_id}" ]
then
  echo
  echo "===== Новый образ соответствует старому, удаление не требуется =="
  exit 0
else
  echo
  echo "===== Новый образ: ${new_image_id}, старый образ (${prev_image_id}) - убираем"
  ${DKR} rmi ${prev_image_id}
fi

