#! /usr/bin/env bash

set -euo pipefail

helm upgrade --install release_name airflow \
--repo https://helm.astronomer.io \
--version "v1.13.5" \
--namespace the_namespace \
--values values.yaml \
--debug \
--reset-values \
--wait
