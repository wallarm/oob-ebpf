#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-wallarm-oob}
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/kind-config-$KIND_CLUSTER_NAME}"

WALLARM_API_HOST="${WALLARM_API_HOST:-api.wallarm.com}"
WALLARM_API_CA_VERIFY="${WALLARM_API_CA_VERIFY:-true}"

SMOKE_SUITE_IMAGE="${SMOKE_SUITE_IMAGE:-"dkr.wallarm.com/tests/smoke-tests:latest"}"
SMOKE_PYTEST_ARGS=$(echo "${SMOKE_PYTEST_ARGS:---allure-features=MonitoringMode}" | xargs)
SMOKE_PYTEST_WORKERS="${SMOKE_PYTEST_WORKERS:-1}"
SMOKE_HOSTNAME_OLD_NODE="${SMOKE_HOSTNAME_OLD_NODE:-smoke-tests-old-node}"

declare -a mandatory
mandatory=(
  WALLARM_CLIENT_ID
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
  trap 'kubectl delete pod pytest --now  --ignore-not-found' EXIT ERR
  # Colorize pytest output if run locally
  EXEC_ARGS="--tty --stdin"
else
  EXEC_ARGS="--tty"
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

KIND_CLUSTER_IMAGES=$(docker exec -it "${KIND_CLUSTER_NAME}"-control-plane crictl images -o yaml)
if echo "${KIND_CLUSTER_IMAGES}" | grep -q "$SMOKE_SUITE_IMAGE"; then
  echo "Docker image ${SMOKE_SUITE_IMAGE} already present in Kind cluster ${KIND_CLUSTER_NAME}"
else
  echo "Pulling Docker image ${SMOKE_SUITE_IMAGE} ..."
  docker pull --quiet "${SMOKE_SUITE_IMAGE}" > /dev/null
  echo "Loading Docker image ${SMOKE_SUITE_IMAGE} to Kind cluster ${KIND_CLUSTER_NAME} ..."
  kind load docker-image --name="${KIND_CLUSTER_NAME}" "${SMOKE_SUITE_IMAGE}" > /dev/null
fi

echo "Retrieving Wallarm Node UUID ..."
NODE_POD=$(kubectl get pod -l "app.kubernetes.io/component=processing" -o=jsonpath='{.items[0].metadata.name}')
NODE_UUID=$(kubectl logs "${NODE_POD}" -c init | grep 'Registered new instance' | tail -c 36)
echo "Wallarm Node UUID: ${NODE_UUID}"

#TODO When ebpf-agent will be ready, we need to deploy test workload here and get its service address instead
echo "Retrieving Wallarm Node URL ..."
NODE_SVC=$(kubectl get svc -l "app.kubernetes.io/component=processing" -o=jsonpath='{.items[0].metadata.name}')
NODE_URL="http://${NODE_SVC}.default.svc"
echo "Wallarm Node URL: ${NODE_URL}"

echo "Deploying pytest pod ..."
kubectl run pytest \
  --env="NODE_BASE_URL=${NODE_URL}" \
  --env="NODE_UUID=${NODE_UUID}" \
  --env="WALLARM_API_HOST=${WALLARM_API_HOST}" \
  --env="API_CA_VERIFY=${WALLARM_API_CA_VERIFY}" \
  --env="CLIENT_ID=${WALLARM_CLIENT_ID}" \
  --env="USER_UUID=${WALLARM_USER_UUID}" \
  --env="USER_SECRET=${WALLARM_USER_SECRET}" \
  --env="HOSTNAME_OLD_NODE=${SMOKE_HOSTNAME_OLD_NODE}" \
  --image="${SMOKE_SUITE_IMAGE}" \
  --image-pull-policy=Never \
  --pod-running-timeout=1m0s \
  --restart=Never \
  --overrides='{"apiVersion": "v1", "spec":{"terminationGracePeriodSeconds": 0}}' \
  --command -- sleep infinity

kubectl wait --for=condition=Ready pods --all --timeout=60s

echo "Run smoke tests ..."
kubectl exec pytest ${EXEC_ARGS} -- pytest -n "${SMOKE_PYTEST_WORKERS}" "${SMOKE_PYTEST_ARGS}"