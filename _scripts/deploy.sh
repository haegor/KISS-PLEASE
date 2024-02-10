#!/bin/bash
#
# Скрипт нужен для удобства отладки манифестов kubernetes, чтобы не
# набирать одно и тоже. А ещё как шпаргалка.
#
# Файл универсален и может быть подложен к любому манифесту
# Если манифестов несколько, то указать необходимый можно как $2
#
# 2023 (c) haegor
#

[ -f "./settings.sh" ] && . ./settings.sh

[ $2 ] && manifest="$2" || manifest=$( find . -maxdepth 1 -type f \( -iname "*.yml" -or -iname "*.yaml" \) -not -iname "docker-compose.y*ml" -print -quit 2>/dev/null )
#D echo manifest: ${manifest}

f_getkinds () {
    cat ${manifest} | grep -i "kind" | cut -f2 -d:
}

f_getpods () {
    ${kubectl} get po -l app=$1 -o json | jq ".items[].metadata.name" | tr -d \"
}

f_getapplabel () {
    cat ${manifest} | grep -i "app: " | head -1 | tr -d [:blank:] | cut -f2 -d:
}

# Превращает kind-ы в используемые мной суффиксы имён компонентов
f_abbreviate () {
    case "$1" in
    'ConfigMap')
        echo cm
    ;;
    'Deployment')
        echo dpl
    ;;
    'StatefullSet')
        echo ss
    ;;
    'ReplicaSet')
        echo rs
    ;;
    'DaemonSet')
        echo ds
    ;;
    'Service')
        echo svc
    ;;
    'Pod')
        echo pod
    ;;
    'Container')
        echo cont
    ;;
    'Endpoint')
        echo ep
    ;;
    'Ingress')
        echo ingress
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
  if [ "${oddity}" -eq "1" ];
  then
    output+='-'
  fi

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
'replace'|'rep'|'repl') #
    ${kubectl} replace -f "${manifest}"
;;
'apply')
    ${kubectl} apply -f "${manifest}"
;;
'create'|'cr'|'create.sh') #
    ${kubectl} create -f "${manifest}"
;;
'pods'|'po'|'ps')
    app_label=$(f_getapplabel)
    ${kubectl} get po -l app=${app_label} -o wide --show-labels
;;
'ep'|'eps')
    app_label=$(f_getapplabel)
    ${kubectl} get ep -l app=${app_label} -o wide --show-labels
;;
'rs'|'replicaset')
    app_label=$(f_getapplabel)
    ${kubectl} get rs -l app=${app_label} -o wide --show-labels
;;
'nodes'|'no')
    ${kubectl} get no -L data_storage,vds,foreign
;;
'copy'|'cp') 		# TODO перепроверить
     if [ "$2" ]
     then
         copied_file="$2"
     else
         echo "Не указан файл для копирования"
         exit 0
     fi

     [ -f "${extract_dir}" ] || mkdir -p "${extract_dir}"

     pod=$(f_getpods $(f_getapplabel) | head -1)
     bn="$(basename ${copied_file})"

     ${kubectl} cp "${namespace}/${pod}:${copied_file}" "${extract_dir}/${bn}"
;;
'show'|'ls'|'get') #
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
'logs'|'log')
    pods=$(f_getpods $(f_getapplabel))
    ${kubectl} logs ${pods}
;;
'journal') #
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
'prev-logs'|'prev') #
    pods=$(f_getpods $(f_getapplabel))
    ${kubectl} logs ${pods} --previous
;;
'desc'|'de') #
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
'yaml'|'yml') #
    app_label=$(f_getapplabel)
    ${kubectl} get po -l app=${app_label} -o yaml
;;
'enter'|'enter.sh')
#    app_label=$(f_getapplabel)
#    pod=$(${kubectl} get po -l app=${app_label} | grep -v '^NAME' | head -1 | cut -f1 -d' ')

    pod=$($0 pods | grep -v '^NAME' | head -1 | cut -f1 -d' ')

    ${kubectl} exec -it "${pod}" -- ${RUN_COMMAND}
;;
'command'|'comm'|'who-run')
# Да, не через лейбл. Чтобы можно было подписывать результаты в выводе.
    pods=$(f_getpods $(f_getapplabel))

    for i in ${pods}
    do
        echo "pod ${i}: $(${kubectl} exec ${i} -- ps -p 1 -o command | grep -v COMMAND)"
    done
;;
'del'|'delete'|'rm'|'remove'|'rm.sh') #
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
'ing'|'ingress')
    ${kubectl} get ingress --show-labels
;;
'docs') #
    # Это не используется. Это чтобы показать что я про это знаю.
    ${kubectl} explain pods
;;
'run'|'exe'|'exec'|'ent'|'enter'|'enter.sh')
    pod=$(f_getpods $(f_getapplabel)| head -1)
    ${kubectl} exec -it po $pod "${RUN_COMMAND}"
;;
'--help'|'-help'|'help'|'-h'|'*'|'') # Автопомощь. Мы тут.
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

