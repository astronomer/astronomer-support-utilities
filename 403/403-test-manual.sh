#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 [cluster_id] [organization_id] [deployment_id]" 1>&2
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

build_small_random_image () {
  local workdir="$1"
  local tag="$2"

  cd "$workdir" || return $?
  if [[ ! -f random.txt ]]; then
    dd if=/dev/urandom of=random.txt bs=1M count=10 || return $?
  fi
  if [[ ! -f Dockerfile ]]; then
    cat > Dockerfile <<EOF
FROM scratch
ADD random.txt /
EOF
  fi
  docker build -t "$tag" .
  return $?
}

check_token_expiry "$ASTRO_TOKEN" || exit 3

TMPDIR=${TMPDIR:-}
LOCAL_IMAGE=${LOCAL_IMAGE:-}
if [[ -z $TMPDIR ]]; then
  TMPDIR="$(mktemp -d)"
fi
if [[ -z $LOCAL_IMAGE ]]; then
  # The od utility shall write the contents of its input files to standard output in a user-specified format.
  # In our case, 8 psuedorandom bytes represented with two hexadecimal numbers each.
  LOCAL_IMAGE="$(od -v -An -tx1 -N 8 /dev/urandom | tr -d ' \n')"
fi
build_small_random_image "$TMPDIR" "$LOCAL_IMAGE"

LOCAL_TAG="${LOCAL_IMAGE//.*:/}"
REMOTE_HOST="${CLUSTER_ID}.registry.astronomer.run"
REMOTE_IMAGE="${REMOTE_HOST}/${ORGANIZATION_ID}/${DEPLOYMENT_ID}:${LOCAL_TAG}"

echo "push $REMOTE_IMAGE"
echo "$ASTRO_TOKEN" | docker login -u cli --password-stdin "$REMOTE_HOST"
docker tag "$LOCAL_IMAGE" "$REMOTE_IMAGE"
docker push "$REMOTE_IMAGE"
echo "successfully pushed to $CLUSTER_ID"