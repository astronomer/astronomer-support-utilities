#! /usr/bin/env bash

set -euo pipefail

ASTRONOMER_NAMESPACE="astronomer"

POD_NAMES=$(kubectl get pods \
-l 'tier in (astronomer,nginx, logging)' \
--namespace $ASTRONOMER_NAMESPACE \
--no-headers \
--field-selector=status.phase==Running \
--output custom-columns=":metadata.name")

if [ -d logs ]; then
  rm -rf logs
fi

if [ ! -d logs ]; then
  mkdir logs
fi

for i in $POD_NAMES;
do
    SUFFIX=$(openssl rand -hex 2)
    CONTAINER=""
    LOG_NAME=""

    if [[ $i == *"astro-ui"* ]]; then
      CONTAINER="astro-ui"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    # i dont care about cli-install
    if [[ $i == *"cli-install"* ]]; then
      continue
    fi

    if [[ $i == *"commander"* ]]; then
      CONTAINER="commander"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"fluentd"* ]]; then
      CONTAINER="fluentd"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"grafana"* ]]; then
      CONTAINER="grafana"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"houston"* ]]; then
      CONTAINER="houston"
      LOG_NAME=$CONTAINER+$SUFFIX
      if [[ $i == *"houston-worker"* ]]; then
        LOG_NAME="worker"+$SUFFIX
      fi
    fi

    if [[ $i == *"nats"* ]]; then
      CONTAINER="nats"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"nginx"* ]]; then
      if [[ $i == *"default-backend"* ]]; then
        CONTAINER="default-backend"
        LOG_NAME=$CONTAINER+$SUFFIX
      else
        CONTAINER="nginx"
        LOG_NAME=$CONTAINER+$SUFFIX
      fi
    fi

    if [[ $i == *"registry"* ]]; then
      CONTAINER="registry"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"elasticsearch-client"* ]]; then
      CONTAINER="es-client"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"elasticsearch-data"* ]]; then
      CONTAINER="es-data"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"elasticsearch-master"* ]]; then
      CONTAINER="es-master"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"kibana"* ]]; then
      CONTAINER="kibana"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $i == *"stan"* ]]; then
      CONTAINER="stan"
      LOG_NAME=$CONTAINER+$SUFFIX
    fi

    if [[ $CONTAINER = "" ]]; then
      echo "Pod $i is not part of this script. Skipping.."
      continue
    fi

    echo "Collecting logs for the $CONTAINER container in pod $i"

    kubectl -n $ASTRONOMER_NAMESPACE -c $CONTAINER logs $i > logs/$LOG_NAME.log
done

tar --create --file logs.tar logs/

