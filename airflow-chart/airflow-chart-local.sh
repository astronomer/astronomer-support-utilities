#! /usr/bin/env bash

set -euo pipefail

helm upgrade --install james1 /Users/jamesmusselwhite/code/airflow/chart \
--namespace default \
--debug \
--reset-values \
--wait
