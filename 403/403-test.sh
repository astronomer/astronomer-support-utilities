#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 cluster_id organization_id deployment_id" 1>&2
  exit 1
fi

CLUSTER_ID="$1"
ORGANIZATION_ID="$2"
DEPLOYMENT_ID="$3"

if [[ -z $ASTRO_TOKEN ]]; then
  echo "ASTRO_TOKEN is required, get one from cloud.astronomer.io/token" 1>&2
  exit 2
fi

check_token_expiry() {
  local token="$1"

  local expiry_time now
  expiry_time="$(echo "$token" | sed 's/\./\t/g' | cut -f 2 | base64 -d | sed -r 's/.*"exp":([0-9]*).*/\1/')"
  # POSIX-compliant method to get current time in seconds
  # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html#tag_20_06_13_12
  # srand([expr])
  #   Set the seed value for rand to expr or use the time of day if expr is omitted. The previous seed value shall be returned.
  now="$(awk 'BEGIN{print srand(srand())}')"

  if [[ $expiry_time -le $now ]]; then
    echo "ASTRO_TOKEN is expired" 1>&2
    return 1
  fi
}

get_registry_token () {
  local organization_id="$1"
  local deployment_id="$2"

  local response token
  response="$(curl --request GET "https://api.astronomer.io/private/v1alpha1/docker-registry/authorization?account=cli&scope=repository%3A${organization_id}%2F${deployment_id}%3Apush%2Cpull&service=docker-registry" --header 'Content-Type: application/json' -u "cli:$ASTRO_TOKEN" 2>/dev/null)"
  token="$(echo "$response" | jq -r '.token')"

  if [[ -z $token || $token == null ]]; then
    printf "error getting registry token:\n%s\n" "$(echo "$response" | jq)" 1>&2
    return 1
  fi
  echo "$token"
}

check_token_expiry "$ASTRO_TOKEN" || exit 3

REGISTRY_TOKEN="$(get_registry_token "$ORGANIZATION_ID" "$DEPLOYMENT_ID")" || exit 4

curl --head "https://${CLUSTER_ID}.registry.astronomer.run/v2/${ORGANIZATION_ID}/${DEPLOYMENT_ID}/blobs/sha256:6a9d5e1c57fc7c1a03dc73b5566630fbb60349448ba23641812e6c1f9e89ed4b" --header "Authorization: Bearer $REGISTRY_TOKEN"