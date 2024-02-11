#!/bin/bash

if [ $2 ]
then
  cluster_subnet="$2"
else
  cluster_subnet='10.82.0.0/16'
fi

case $1 in
'look'|'show'|'sh')			# Осмотреться
	# Ещё можно вот так: sudo kubectl get po --namespace kube-system --kubeconfig /etc/rancher/k3s/k3s.yaml
	# https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
	k3s ctr c list
	k3s crictl ps
	k3s kubectl get po --namespace kube-system -o wide
	k3s kubectl get nodes -o wide
;;
'get'|'pull')				# Стянуть index.sh
  curl -sfL "https://get.k3s.io"
;;
'stop')					# Остановить всё что связано с k3s
	systemctl stop k3s
	systemctl stop k3s-agent
	k3s-killall.sh
;;
'start')				# Запустить службу k3s
	systemctl start k3s
;;
'status')				# Статус службы k3s
	systemctl status k3s
;;
'init')					#
	k3s server --cluster-init --cluster-cidr "$cluster_subnet"
;;
'reset')				#
	k3s server --cluster-reset
;;
'deploy')				#
	cat ./index.sh | sh -s - server --cluster-init
;;
'install')				#
	cat ./index.sh | sh -s - server --cluster-cidr="$cluster_subnet"
;;
'uninstall')				#
	k3s-uninstall.sh
;;
'test')					# excluder
# Спец. пункт для экспериментов
	k3s server --cluster-cidr "$cluster_subnet"
	# --node-ip 192.168.0.100
;;
'--help'|'-help'|'help'|'-h'|*|'')	# Автопомощь. Мы тут.
  echo
  echo "Недостаточно параметров или они неверно указаны."
  echo "В качестве обязательного параметра указывается его режим."
  echo
  echo "Перечень режимов:"
  grep -P "^\'[[:graph:]]*\'\)[[:space:]]*#?.*$" $0 | grep -v 'excluder'
  echo
  exit 0
;;
esac

