#! /usr/bin/env bash

set -euo pipefail

mkdir -p keys

kubectl get secret \
-n astronomer \
-o jsonpath='{.data.tls\.key}' astronomer-tls | base64 -d > tls.key