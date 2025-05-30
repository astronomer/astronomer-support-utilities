#! /usr/bin/env bash

set -euo pipefail

helm upgrade release_name airflow \
--repo https://helm.astronomer.io \
--version "v1.14.3" \
--namespace the_namespace \
--debug \
--reuse-values \
--wait
