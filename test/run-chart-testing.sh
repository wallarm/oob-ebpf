#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ "${CI:-false}" == "false" ]]; then
  CURDIR="/project"
else
  DOCKER_CMD="docker"
fi


${DOCKER_CMD} run \
  --rm \
  --interactive \
  --network host \
  --name chart-testing \
  --volume ${KUBECONFIG}:/root/.kube/config \
  --volume ${CURDIR}:/workdir \
  --workdir /workdir \
  ${HELM_TEST_IMAGE} ct install \
      --charts helm \
      --helm-extra-set-args "${HELM_ARGS}" \
      --helm-extra-args "--timeout 180s" \
      ${CT_EXTRA_ARGS:-} \
      --debug