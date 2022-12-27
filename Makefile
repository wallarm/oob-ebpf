# https://makefiletutorial.com/

-include .env
.EXPORT_ALL_VARIABLES:

DIR = $(shell cd "$$( dirname "${BASH_SOURCE[0]}" )" && pwd )

VM_NAME    ?= k8s
CONFIG_DIR ?= ${HOME}/.lima/$(VM_NAME)/conf
KUBECONFIG ?= $(CONFIG_DIR)/kubeconfig.yaml

KUBECTL_CMD := KUBECONFIG=$(KUBECONFIG) kubectl
HELM_CMD    := KUBECONFIG=$(KUBECONFIG) helm
SHELL_CMD   := limactl shell $(VM_NAME) sudo
DOCKER_CMD  := $(SHELL_CMD) nerdctl -n k8s.io

all: env-init helm-install smoke-test
.PHONY: all

### Local dev env routines
###
env-init:
	CURDIR=$(CURDIR) envsubst '$${CURDIR}' < "lima/k8s.yaml" > "lima/k8s.yaml.rendered"
	limactl start --name $(VM_NAME) --tty=false $$(pwd)/lima/k8s.yaml.rendered
	make env-get-config
	$(KUBECTL_CMD) get nodes

env-get-config:
	@[ -d $(CONFIG_DIR) ] || mkdir mkdir $(CONFIG_DIR)
	$(SHELL_CMD) cat /etc/kubernetes/admin.conf > $(KUBECONFIG)
	@echo "Execute: export KUBECONFIG=$(KUBECONFIG)"

env-stop:
	@limactl stop $(VM_NAME) || limactl stop -f $(VM_NAME)

env-start:
	@limactl start $(VM_NAME)
	make env-get-config

env-down: env-stop
	@limactl delete $(VM_NAME)

env-status:
	@limactl list $(VM_NAME)

env-shell:
	$(SHELL_CMD) -i

env-k9s:
	KUBECONFIG=$(KUBECONFIG) k9s

.PHONY: env-*

### Helm routines
###
HELM_EXTRA_ARGS +=
HELM_TEST_IMAGE += "quay.io/dmitriev/chart-testing:latest-amd64"
HELM_ARGS := --set config.api.token=${WALLARM_API_TOKEN} $(HELM_EXTRA_ARGS)

helm-template:
	$(HELM_CMD) template wallarm-oob ./helm $(HELM_ARGS) --debug

helm-install:
	$(HELM_CMD) upgrade --install oob-ebpf ./helm $(HELM_ARGS) --wait
	$(KUBECTL_CMD) wait --for=condition=Ready pods --all --timeout=90s

helm-uninstall:
	$(HELM_CMD) uninstall oob-ebpf

helm-test:
	@test/run-chart-testing.sh

.PHONY: helm-*

## Run smoke tests (expects access to a working Kubernetes cluster).
smoke-test:
	@test/run-smoke-suite.sh

.PHONY: smoke-test
