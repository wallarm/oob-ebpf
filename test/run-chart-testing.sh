#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#TODO handler for CI
if [[ "${CI:-false}" == "false" ]]; then
  PROJECT_DIR="/project"
  KUBECONFIG="/etc/kubernetes/admin.conf"
else
  PROJECT_DIR="${DIR}"
  DOCKER_CMD="docker"
fi

${DOCKER_CMD} run \
  --rm \
  --interactive \
  --network host \
  --name chart-testing \
  --volume ${KUBECONFIG}:/root/.kube/config \
  --volume ${PROJECT_DIR}:/workdir \
  --workdir /workdir \
  ${HELM_TEST_IMAGE} ct install \
      --charts helm \
      --helm-extra-set-args "${HELM_ARGS}" \
      --helm-extra-args "--timeout 180s" \
      ${CT_EXTRA_ARGS:-} \
      --debug