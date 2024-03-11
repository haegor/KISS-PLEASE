#!/bin/bash

deploys=$(find ./ -mindepth 2 -maxdepth 2 -type l -name "deploy.sh")

case $1 in
'create')
    command=create
;;
'rm')
    command=rm
;;
*)		# default
    command=create
;;
esac


for i in $deploys
do
    file=$(basename ${i})
    dir=$(dirname ${i})

    cd "${dir}"

    manifests=$( find . -mindepth 1 -maxdepth 1 -type f \( -iname "*.yml" -or -iname "*.yaml" \) -not -iname "docker-compose.y*ml"} )

    for j in ${manifests}
    do
        ./deploy.sh ${command} "${j}"
    done

    cd ../
done
