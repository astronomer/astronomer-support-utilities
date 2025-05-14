#! /usr/bin/env bash

set -euo pipefail

VERSION="v1.14.3"

helm upgrade --install airflow airflow \
--repo https://helm.astronomer.io \
--version $VERSION \
--namespace airflowtest \
--values adpts-master.yaml \
--debug \
--reset-values \
--wait

