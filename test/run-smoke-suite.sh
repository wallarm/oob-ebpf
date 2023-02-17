#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Variables required for pulling Docker image with smoke tests
REGISTRY_NAME="dkr.wallarm.com"
IMAGE_PULL_SECRET_NAME="wallarm-registry-creds"

# Variables required for smoke test
WALLARM_API_HOST="${WALLARM_API_HOST:-api.wallarm.com}"
WALLARM_API_CA_VERIFY="${WALLARM_API_CA_VERIFY:-true}"
WALLARM_CLIENT_ID="${WALLARM_CLIENT_ID:-4}"

SMOKE_SUITE_IMAGE="${SMOKE_SUITE_IMAGE:-"${REGISTRY_NAME}/tests/smoke-tests:latest"}"
SMOKE_PYTEST_ARGS=$(echo "${SMOKE_PYTEST_ARGS:--s --dist=no --allure-features=MonitoringMode}" | xargs)
SMOKE_PYTEST_WORKERS="${SMOKE_PYTEST_WORKERS:-0}"
SMOKE_HOSTNAME_OLD_NODE="${SMOKE_HOSTNAME_OLD_NODE:-smoke-tests-old-node}"

WORKLOAD_NS="test-oob-ebpf"

declare -a mandatory
mandatory=(
  WALLARM_USER_UUID
  WALLARM_USER_SECRET
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

if [[ "${CI:-false}" == "false" ]]; then
  trap 'kubectl delete pod pytest --now --ignore-not-found' EXIT ERR
  # Colorize pytest output if run locally
  EXEC_ARGS="--tty --stdin"
  CURDIR="/project"
  #TODO Handle uploading image with smoke-tests to Lima VM (k8s.io namespace)
  IMAGE_PULL_POLICY="Never"
  IMAGE_PULL_SECRETS="[]"
else
  EXEC_ARGS="--tty"
  IMAGE_PULL_POLICY="IfNotPresent"
  IMAGE_PULL_SECRETS="[{\"name\": \"${IMAGE_PULL_SECRET_NAME}\"}]"

  echo "Creating secret ${IMAGE_PULL_SECRET_NAME} with registry credentials ..."
  kubectl create secret docker-registry ${IMAGE_PULL_SECRET_NAME} \
    --docker-server="${REGISTRY_NAME}" \
    --docker-username="${REGISTRY_TOKEN_NAME}" \
    --docker-password="${REGISTRY_TOKEN_SECRET}" \
    --docker-email=docker-pull@unexists.unexists
fi


echo "Deploying test workload ..."
kubectl create namespace "${WORKLOAD_NS}"
kubectl -n "${WORKLOAD_NS}" apply -f "${CURDIR}/test/workload.yaml"
kubectl -n "${WORKLOAD_NS}" wait --for=condition=Ready pods --all --timeout=60s

echo "Retrieving test workload URL ..."
WORKLOAD_SVC=$(kubectl -n "${WORKLOAD_NS}" get svc -l "app=workload" -o=jsonpath='{.items[0].metadata.name}')
WORKLOAD_URL="http://${WORKLOAD_SVC}.${WORKLOAD_NS}.svc"
echo "Test workload URL: ${WORKLOAD_URL}"

echo "Retrieving Wallarm Node UUID ..."
NODE_POD=$(kubectl get pod -l "app.kubernetes.io/component=processing" -o=jsonpath='{.items[0].metadata.name}')
NODE_UUID=$(kubectl logs "${NODE_POD}" -c init | grep 'Registered new instance' | tail -c 36)
echo "Wallarm Node UUID: ${NODE_UUID}"

echo "Deploying pytest pod ..."
kubectl run pytest \
  --env="NODE_BASE_URL=${WORKLOAD_URL}" \
  --env="NODE_UUID=${NODE_UUID}" \
  --env="WALLARM_API_HOST=${WALLARM_API_HOST}" \
  --env="API_CA_VERIFY=${WALLARM_API_CA_VERIFY}" \
  --env="CLIENT_ID=${WALLARM_CLIENT_ID}" \
  --env="USER_UUID=${WALLARM_USER_UUID}" \
  --env="USER_SECRET=${WALLARM_USER_SECRET}" \
  --env="HOSTNAME_OLD_NODE=${SMOKE_HOSTNAME_OLD_NODE}" \
  --env="LOG_LEVEL=DEBUG" \
  --image="${SMOKE_SUITE_IMAGE}" \
  --image-pull-policy=${IMAGE_PULL_POLICY} \
  --pod-running-timeout=1m0s \
  --restart=Never \
  --overrides='{"apiVersion": "v1", "spec":{"terminationGracePeriodSeconds": 0, "imagePullSecrets": '"${IMAGE_PULL_SECRETS}"'}}' \
  --command -- sleep infinity

kubectl wait --for=condition=Ready pods --all --timeout=60s

echo "Run smoke tests ..."
kubectl exec pytest ${EXEC_ARGS} -- pytest -n "${SMOKE_PYTEST_WORKERS}" "${SMOKE_PYTEST_ARGS}"