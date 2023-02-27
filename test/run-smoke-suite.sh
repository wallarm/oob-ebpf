#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Variables required for pulling Docker image with smoke tests
REGISTRY_NAME="dkr.wallarm.com"
IMAGE_PULL_SECRET_NAME="tests-registry-creds"

# Variables required for smoke test
WALLARM_API_HOST="${WALLARM_API_HOST:-api.wallarm.com}"
WALLARM_API_CA_VERIFY="${WALLARM_API_CA_VERIFY:-true}"
WALLARM_CLIENT_ID="${WALLARM_CLIENT_ID:-4}"

SMOKE_SUITE_IMAGE="${REGISTRY_NAME}/tests/smoke-tests:latest"
SMOKE_PYTEST_ARGS=$(echo "${SMOKE_PYTEST_ARGS:---allure-features=MonitoringMode}" | xargs)
SMOKE_PYTEST_WORKERS=0
SMOKE_HOSTNAME_OLD_NODE="smoke-tests-old-node"

WORKLOAD_NS="test-oob-ebpf"

declare -a mandatory
mandatory=(
  WALLARM_USER_UUID
  WALLARM_USER_SECRET
  REGISTRY_TOKEN_NAME
  REGISTRY_TOKEN_SECRET
)

missing=false
for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable $var must be set"
    missing=true
  fi
done

if [ "$missing" = true ]; then
  exit 1
fi

if ! kubectl get secret "${IMAGE_PULL_SECRET_NAME}" &> /dev/null; then
  echo "Creating secret ${IMAGE_PULL_SECRET_NAME} with registry credentials ..."
  kubectl create secret docker-registry ${IMAGE_PULL_SECRET_NAME} \
    --docker-server="${REGISTRY_NAME}" \
    --docker-username="${REGISTRY_TOKEN_NAME}" \
    --docker-password="${REGISTRY_TOKEN_SECRET}" \
    --docker-email=docker-pull@unexists.unexists
fi

echo "Deploying test workload ..."
! kubectl get namespace "${WORKLOAD_NS}" &> /dev/null && kubectl create namespace "${WORKLOAD_NS}"
kubectl -n "${WORKLOAD_NS}" apply -f "${CURDIR}/test/workload.yaml"
kubectl -n "${WORKLOAD_NS}" wait --for=condition=Ready pods --all --timeout=60s

echo "Retrieving test workload URL ..."
WORKLOAD_SVC=$(kubectl -n "${WORKLOAD_NS}" get svc -o name | cut -d'/' -f 2)
WORKLOAD_HOST="${WORKLOAD_SVC}.${WORKLOAD_NS}.svc"
echo "Test workload host: ${WORKLOAD_HOST}"

echo "Retrieving Wallarm Node UUID ..."
NODE_POD=$(kubectl get pod -l "app.kubernetes.io/component=processing" -o=jsonpath='{.items[0].metadata.name}')
NODE_UUID=$(kubectl logs "${NODE_POD}" -c init | grep 'Registered new instance' | tail -c 36)
echo "Wallarm Node UUID: ${NODE_UUID}"

echo "Deploying pytest pod ..."
trap 'kubectl delete pod pytest --now --ignore-not-found' EXIT ERR
kubectl run pytest \
  --env="NODE_UUID=${NODE_UUID}" \
  --env="WALLARM_API_HOST=${WALLARM_API_HOST}" \
  --env="API_CA_VERIFY=${WALLARM_API_CA_VERIFY}" \
  --env="CLIENT_ID=${WALLARM_CLIENT_ID}" \
  --env="USER_UUID=${WALLARM_USER_UUID}" \
  --env="USER_SECRET=${WALLARM_USER_SECRET}" \
  --env="HOSTNAME_OLD_NODE=${SMOKE_HOSTNAME_OLD_NODE}" \
  --image="${SMOKE_SUITE_IMAGE}" \
  --image-pull-policy="IfNotPresent" \
  --pod-running-timeout=1m0s \
  --restart=Never \
  --overrides='{"apiVersion": "v1", "spec":{"terminationGracePeriodSeconds": 0, "imagePullSecrets": [{"name": "'"${IMAGE_PULL_SECRET_NAME}"'"}]}}' \
  --command -- sleep infinity

kubectl wait --for=condition=Ready pods --all --timeout=60s

echo "Run smoke tests for HTTP ..."
kubectl exec pytest --tty --stdin -- bash -c "NODE_BASE_URL=http://${WORKLOAD_HOST} pytest -n ${SMOKE_PYTEST_WORKERS} ${SMOKE_PYTEST_ARGS}"