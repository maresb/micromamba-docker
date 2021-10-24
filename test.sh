#!/bin/bash
set -eu -o pipefail

FLAGS=
if which parallel > /dev/null; then
  if [[ $(uname -s) == "Darwin" ]]; then
    NUM_CPUS=$(sysctl -n hw.ncpu)
  else
    NUM_CPUS=$(nproc)
  fi
  FLAGS="--jobs $NUM_CPUS"
  if [ "$NUM_CPUS" -gt "1" ]; then
    PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    # build main test image here so that each *.bats file doesn't do this work in
    # parallel. The *.bats files will still run this docker command, but it will
    # just be a cache hit.
    for IMAGE_INFO in $(cut -f2 "${PROJECT_ROOT}/tags.tsv"); do
      IFS=';' read -ra IMAGE_ARRAY <<< "$IMAGE_INFO"
      BASE_IMAGE="${IMAGE_ARRAY[0]}"
      DEBIAN_NAME="${IMAGE_ARRAY[1]}"
      docker build --quiet \
	           --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
                   "--tag=micromamba:test-${DEBIAN_NAME}" \
                   "--file=${PROJECT_ROOT}/Dockerfile" \
                   "$PROJECT_ROOT" > /dev/null
    done
  fi
fi

./test/bats/bin/bats $FLAGS $@ test/
