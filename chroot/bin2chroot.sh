#!/bin/bash
#
# Рекурсивно копирует указанный бинарник и все его зависимости с сохранением
# путей в указанную папку.
#
# В качестве параметров принимает:
# $1 - бинарник, доступный через пути из $PATH. По умолчанию - bash
# [$2] - папка, куда следует положить chroot. По умолчанию ./work_dir
#
# 2023 (c) haegor
#
# TODO: сделать нормальную помощь.
#

# Настройки по умолчанию
default_dir='./work_dir/'
default_binary="$(which bash)"

cp='sudo cp'
mkdir='sudo mkdir'

##### bin arguments ############################################################
if [ -n "$1" ]
then
  if [ -f "$1" ] || [ -L "$1" ]		# Это прямое указание пути до файла?
  then
    target_command="$1"
  else					# Значит относительное
    target_command="$(which $1)"

    if [ ! "${target_command}" ]	# Ну значит не относительное
    then
      echo "Невозможно найти указанный elf или библиотеку"
      exit 0
    fi
  fi
else
    target_command="${default_binary}"	# И нечего мучаться
fi

echo "Обрабатываемая комманда: ${target_command}"

##### dir arguments ############################################################

if [ -n "$2" ]
then
    if [ -d "$2" ] || [ -L "$2" ]
    then
      target_dir="$2"			# Существующая директория или ссылка
    elif [ -f "$2" ]			# Обычный файл
    then
      echo "Ошибка. В качестве директории назначения указан обычный файл."
      exit 0
    else				# Что-то не существующее
      target_dir="$2"
      [ ! -d "${target_dir}" ] && ${mkdir} -p "${target_dir}"
    fi
else
    target_dir="${default_dir}"		# default

    [ ! -d "${target_dir}" ] \
      && ${mkdir} -p "${target_dir}"
fi

echo "Рабочая директория: ${target_dir}"

##### other arguments ##########################################################

[ -n "$3" ] && { echo "Слишком много аргументов."; exit 0; }

##### Отдел функций ############################################################

f_dependencies () {
  ldd $1 | grep -v -P '^\tlinux-vdso.so.1' | tr -d "\t"
}

f_parse_dep_line () {
   local full_path=$(echo "$1" | grep -P "^/")
   local shared=$(echo "$1" | grep '=>')
   local staticly_linked=$(echo "$1" | grep 'statically linked')

   if [ -n "${full_path}" ]
   then
     intermidiate=$(echo "${full_path}")
     echo "${intermidiate:0:-21}"
   fi

   if [ -n "${shared}" ]
   then
     intermidiate=$(echo "${shared}" | cut -f2 -d'>' )
     echo "${intermidiate:1:-21}"
   fi

   if [ -n "${staticly_linked}" ]
   then
     echo ''
   fi
}

f_copy_bin () {
  ${cp} --parents --update "$1" "${target_dir}"
}

# Вот за такие вещи я и недолюбливаю bash. Обходим некрасивости его
# организации работы с массивами через функции.
f_stack_top_value () {
  echo "${stack[((${#stack[@]}-1))]}"
}

f_stack_top_index () {
  let stack_top_index=${#stack[@]}-1
  echo "${stack_top_index}"
}

f_stack_count () {
  echo "${#stack[@]}"
}

# Проверяет присутствие элемента в списке
f_check4duplicity () {
  local value="$1"

  let dupes_top_index=${#dupes[@]}-1

  found="false"

  for i in $(seq 0 ${dupes_top_index})
  do
    [ "${dupes[i]}" == "${value}" ] && { found="true"; break; }
  done
  echo ${found}
}

# Функция исключительно для дебага
f_look_around_stack () {
  echo "<---"

  stack_count=$(f_stack_count)
  echo "Всего элементов в стеке: ${stack_count}"

  if [ ! ${stack_count} -eq 0 ]
  then
    stack_top_value="$(f_stack_top_value)"
    echo "Значение вершины стека: ${stack_top_value}"

    let stack_top_index=$(f_stack_top_index)
    echo "Индекс вершины стека: ${stack_top_index}"
  else
        echo "В стеке больше нет элементов"
  fi
  echo "--->"
}

##### MAIN #####################################################################

stack[${#stack[@]}]="${target_command}"
#D echo "----- НАЧАЛЬНОЕ ПОЛОЖЕНИЕ ----- " && echo "$(f_look_around_stack)"

# Рекурсия с дедупликацией.
while [ ${#stack[@]} -gt 0 ]
do
    #D echo "<<< НАЧАЛО ИТЕРАЦИИ <<<" && echo "$(f_look_around_stack)"

    stack_top_value="$(f_stack_top_value)"

    # Добавляем ещё один массив, для уникальных бинарников
    if [ "$(f_check4duplicity ${stack_top_value})" == 'true' ]
    then
        unset stack[$(f_stack_top_index)]	# Удаляем из стека
        continue
    else
        dupes[${#dupes[@]}]=${stack_top_value}	# Добавляем в обработанные
    fi

    echo "Копируем: ${stack_top_value}"
    f_copy_bin "${stack_top_value}"		# Копируем
    unset stack[$(f_stack_top_index)]		# Удаляем из стека

    #D echo "--- ПОСЛЕ УДАЛЕНИЯ : ---" && echo "$(f_look_around_stack)"

    deps=$(f_dependencies "${stack_top_value}")
    [ ! -n "${deps}" ] && continue

    while read LINE
    do
        #D echo "-${LINE}-"

        dep_line=`f_parse_dep_line "${LINE}"`

        [ ! "${dep_line}" ] && continue

        stack_count=$(f_stack_count)		# "Берём номерок"
        stack[${stack_count}]="${dep_line}" 	# Добавляем в стек

        #D && echo "В стек добавлено: ${dep_line}"
    done < <(echo "${deps}")

    #D echo "$(f_look_around_stack)" && echo ">>> КОНЕЦ ИТЕРАЦИИ >>>"

done < <(echo "${deplist}")
