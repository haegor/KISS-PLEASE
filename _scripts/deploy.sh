#!/bin/bash
#
# Скрипт нужен для удобства отладки манифестов kubernetes, чтобы не
# набирать одно и тоже. А ещё как шпаргалка.
#
# Файл универсален и может быть подложен к любому манифесту
# Если манифестов несколько, то указать необходимый можно как $2
#
# 2023-2024 (c) haegor
#

[ -f "./settings.sh" ] && source ./settings.sh
# source ./settings.sh || { echo "Файл настроек не обнаружен. Останов."; exit 0; }

[ -n "$2" ] \
  && manifest="$2" \
  || manifest=$( find . -maxdepth 1 -type f \( -iname "*.yml" -or -iname "*.yaml" \) -not -iname "docker-compose.y*ml" -print -quit 2>/dev/null )

f_getkinds () {
    cat ${manifest} | grep -i "kind" | cut -f2 -d:
}

f_getpods () {
    ${kubectl} get po -l app="$1" -o json | jq ".items[].metadata.name" | tr -d \"
}

f_getapplabel () {
    cat ${manifest} | grep -i "app: " | head -1 | tr -d [:blank:] | cut -f2 -d:
}

# Превращает kind-ы в используемые мной суффиксы имён компонентов
f_abbreviate () {
    case "$1" in
    'ConfigMap')     echo cm;		;;
    'Deployment')    echo dpl;		;;
    'StatefullSet')  echo ss;		;;
    'ReplicaSet')    echo rs;		;;
    'DaemonSet')     echo ds;		;;
    'Service')       echo svc;		;;
    'Pod')           echo pod;		;;
    'Container')     echo cont;		;;
    'Endpoint')      echo ep;		;;
    'Ingress')       echo ingress;	;;
    esac
}

####### Ниже идут 3 сугубо оформительские функции. Чтобы рисовать одинаковые строки #################################

f_edge_sized_left () {
  dashes_whole_len=$1
  left_length=$(( ${dashes_whole_len}/2 ))

  output=''
  for i in $(seq 1 ${left_length})
  do
    output+='-'
  done

  echo ${output}
}

f_edge_sized_right () {
  dashes_whole_len=$1

  # Oстаток от деления
  oddity=$(( ${dashes_whole_len} % 2 ))

  # Правое - это такое же левое...
  output=$(f_edge_sized_left $1)

  # .. но с поправкой на 1 символ. Для ровности длины строк вне зависимости от чётности количества их символов
  [ "${oddity}" -eq "1" ] && output+='-'

  echo ${output}
}

f_form_string () {
  output=$1
  output_len=$(echo -n ${output} | wc --chars)

  let dashes_whole_len=(132-2-${output_len})

  string_left=$(f_edge_sized_left ${dashes_whole_len})
  string_right=$(f_edge_sized_right ${dashes_whole_len})

  echo "${string_left} ${output} ${string_right}"
}

# ======================== MAIN ======================================
case $1 in
'replace'|'rep'|'repl')				# Заменяет манифест
  ${kubectl} replace -f "${manifest}"
;;
'apply')					# Применяет манифест
  ${kubectl} apply -f "${manifest}"
;;
'create'|'cr'|'create.sh')			# Создаёт объекты по манифесту
  ${kubectl} create -f "${manifest}"
;;
'pods'|'po'|'ps')				# Список подов
  app_label=$(f_getapplabel)
  ${kubectl} get po -l app=${app_label} -o wide --show-labels
;;
'ep'|'eps')					# Список endpoints
  app_label=$(f_getapplabel)
  ${kubectl} get ep -l app=${app_label} -o wide --show-labels
;;
'rs'|'replicaset')				# Список репликасетов
  app_label=$(f_getapplabel)
  ${kubectl} get rs -l app=${app_label} -o wide --show-labels
;;
'nodes'|'no')					# Выводит список нод с 3мя избранными тегами
  ${kubectl} get no -L datastorage,trust,schedule
;;
'cert2secret')					# Подгружает сертификат сайта как секрет
  bn=$(basename $(pwd))

  ${kubectl} create secret tls $bn.$domain-secret --cert="${certs_dir}/$bn.$domain.crt" --key="${certs_dir}/$bn.$domain.key"
;;
'copy'|'cp')					# Вытаскивает файл из контейнера в папку ./extracted
  # TODO перепроверить
  [ -n "$2" ] && copied_file="$2" || { echo "Не указан файл для копирования"; exit 0; }

  if [ ! -d "${extract_dir}" ]
  then
    mkdir -p "${extract_dir}" \
      || { echo "Невозможно создать папку ${extract_dir}"; exit 0; }
  fi

  pod=$(f_getpods $(f_getapplabel) | head -1)
  bn="$(basename ${copied_file})"

  ${kubectl} cp "${namespace}/${pod}:${copied_file}" "${extract_dir}/${bn}"
;;
'show'|'ls'|'get')				# Показать все объекты, связанные с манифестом
  kinds=$(f_getkinds)
  app_label=$(f_getapplabel)

  for kind in ${kinds}
  do
    echo $(f_form_string "=== ${kind}: ===")
    echo ${kubectl} get ${kind} -l app=${app_label}

    ${kubectl} get ${kind} -l app=${app_label}

    # Вывод дополнительной информации
    case $kind in
    'Deployment')
      echo $(f_form_string "ReplicaSet:")
      $0 replicaset "${manifest}"
    ;;
    'ReplicaSet'|'DaemonSet'|'CronJob')
      echo $(f_form_string "PODS:")
      $0 pods "${manifest}"
    ;;
    'Service')
      echo $(f_form_string "Endpoints:")
      $0 eps "${manifest}"
    ;;
    esac
  done
;;
'logs'|'log')					# Просмотр логов для подов, описанного в манифесте
# TODO Переделать на множественное количество, перепроверить
  pods=$(f_getpods $(f_getapplabel))
  ${kubectl} logs ${pods}
;;
'prev-logs'|'prev')				# Просмотр предыдущего журнала
  pods=$(f_getpods $(f_getapplabel))
  ${kubectl} logs ${pods} --previous
;;
'journal')					# Просмотр журнала (describe) пода
# TODO перепроверить
# haegor@vetinari:~/dev/timeline/rundeck$ k3s kubectl logs -l app=rundeck

  pods=$(f_getpods $(f_getapplabel))

  for i in ${pods}
  do
    echo $(f_form_string "=== POD: ${i} ===")
    echo $(f_form_string "k8s Logs:")
    ${kubectl} logs ${i}

    # Эта секция сработает только на той ноде, куда распланирован контейнер
    containers=$(${kubectl} describe po ${i} | grep "Container ID" | cut -f3 -d: | cut -c 3- -)
    for j in ${containers}
    do
      echo $(f_form_string "crictl inspect:")
      ${crictl} inspect ${j}
    done
  done

  echo $(f_form_string "Events:")
  ${kubectl} get events
;;
'desc'|'de')					#
# TODO перепроверить
  kinds=$(f_getkinds)
  app_label=$(f_getapplabel)

  for kind in ${kinds}
  do
    echo $(f_form_string "=== ${kind} ===")
    echo ${kubectl} get ${kind} -l app=${app_label}
    ${kubectl} describe ${kind} -l app=${app_label}

    case $kind in
    'ReplicaSet'|'DaemonSet'|'CronJob')
       echo $(f_form_string "PODS:")
       echo ${kubectl} describe po -l app=${app_label}
       ${kubectl} describe po -l app=${app_label}
    ;;
    'Service')
       echo $(f_form_string "Endpoints:")
       echo ${kubectl} describe ep -l app=${app_label}
       ${kubectl} describe ep -l app=${app_label}
    ;;
    esac
  done
;;
'yaml'|'yml')					# Вытащить yaml описания всех подов соотвествующих метке подов из манифеста
  app_label=$(f_getapplabel)
  ${kubectl} get po -l app=${app_label} -o yaml
;;
'del'|'delete'|'rm'|'remove'|'rm.sh')		# Удалить всё что создавалось манифестом
  kinds=$(f_getkinds)
  app_label=$(f_getapplabel)

  for kind in ${kinds}
  do
    ${kubectl} delete ${kind} -l app=${app_label}

    if [ "$kind" == "ReplicaSet" ] || [ "$kind" == "DaemonSet" ] || [ "$kind" == "CronJob" ]
    then
      ${kubectl} delete po -l app=${app_label}
    fi
  done
;;
'ing'|'ingress')				# Посмотреть все ингрессы
  ${kubectl} get ingress --show-labels
;;
'docs')						# Шпаргалка по шпаргалкам.
  echo "${kubectl} api-resources"
  echo "${kubectl} explain pods.spec.volumes.secret.items.key"
;;
'command'|'comm'|'who-run')			# Вывести список команд, запущенных в подах
# Да, не через лейбл. Чтобы можно было подписывать результаты в выводе.
  pods=$(f_getpods $(f_getapplabel))

  for i in ${pods}
  do
    echo "pod ${i}: $(${kubectl} exec ${i} -- ps -p 1 -o command | grep -v COMMAND)"
  done
;;
'enter'|'enter.sh'|'dive_in.sh')		# Нырнуть в под
#  app_label=$(f_getapplabel)
#  pod=$(${kubectl} get po -l app=${app_label} | grep -v '^NAME' | head -1 | cut -f1 -d' ')

  pod=$($0 pods | grep -v '^NAME' | head -1 | cut -f1 -d' ')

  ${kubectl} exec -it "${pod}" -- ${RUN_COMMAND}
;;
'run'|'exe'|'exec'|'ent')			# Выполнение указанной команды
  pod=$(f_getpods $(f_getapplabel)| head -1)
  ${kubectl} exec -it po $pod "${RUN_COMMAND}"
;;
'--help'|'-help'|'help'|'-h'|'*'|'')		# Автопомощь. Мы тут.
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
