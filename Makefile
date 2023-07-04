K8S_DIR := k8s
K8S_REPO := https://github.com/kubernetes/kubernetes
K8S_COMMIT := v1.27.3 # d5fdf3135e7 # TODO v1.27.2
K8S_BIN := $(K8S_DIR)/_output/bin
TPP_DIR := $(K8S_DIR)/vendor/github.com/BenjaminSaintCyr/k8s-lttng-tpp

BACKUP_DIR := .bckp
PATCH_FILE := lttng.patch
DATE := $(shell date +"%Y-%m-%d:%H:%M:%S")

# cache
CACHE_DIR := .cache
K8S_ZIP := $(BACKUP_DIR)/$(K8S_DIR).zip
SENTINEL_PATCH := $(CACHE_DIR)/.patch-applied
SENTINEL_BUILD := $(CACHE_DIR)/.k8s-built
SENTINEL_VENDOR := $(CACHE_DIR)/.vendor-installed

SOURCE_DIR=cmd pkg
BUILD_DIR=hack build

.PHONY: all
all: setup-vms build-k8s

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build-k8s:      Build Kubernetes with LTTng support"
	@echo "  setup-vms:      Launch 1 master and 2 worker nodes"
	@echo "  deploy-k8s:     Deploy k8s"
	@echo "  clean:          Clean up and revert the Kubernetes repository to its original state"
	@echo "  help:           Show this help message"

# Build section
$(CACHE_DIR):
	mkdir -p $(CACHE_DIR)

.PHONY: build-k8s
build-k8s: $(K8s_DIR) patch vendor tracer $(SENTINEL_BUILD)

$(SENTINEL_BUILD): $(CACHE_DIR)
	@echo "* Building Kubernetes..."
	(cd $(K8S_DIR) && make)
	@touch $(SENTINEL_BUILD)

$(BACKUP_DIR):
	mkdir -p $(BACKUP_DIR)

$(K8S_DIR) $(K8S_ZIP): $(BACKUP_DIR)
	@echo "* Installing Kubernetes..."
	@if [ -f $(K8S_ZIP) ]; then \
		echo "** Restoring Kubernetes..."; \
		unzip -q $(K8S_ZIP); \
	else \
		echo "** Downloading Kubernetes..."; \
		git clone $(K8S_REPO) $(K8S_DIR) && \
		(cd $(K8S_DIR) && git checkout $(K8S_COMMIT)) && \
		zip -rq $(K8S_ZIP) $(K8S_DIR); \
	fi

.PHONY: patch
patch: $(K8S_DIR) $(SENTINEL_PATCH)

$(SENTINEL_PATCH): $(PATCH_FILE) $(CACHE_DIR)
	@echo "* Applying the lttng patch..."
	cp $(PATCH_FILE) k8s
	(cd $(K8S_DIR) && git apply $(PATCH_FILE))
	@touch $(SENTINEL_PATCH)

.PHONY: update-patch
update-patch: $(K8S_DIR) $(BACKUP_DIR)
	@echo "* Updating lttng patch"
	mv $(PATCH_FILE) $(BACKUP_DIR)/$(DATE).patch
	(cd $(K8S_DIR) && git add $(SOURCE_DIR) $(BUILD_DIR))
	(cd $(K8S_DIR) && git diff --cached > $(PATCH_FILE))
	@cp $(K8S_DIR)/$(PATCH_FILE) $(PATCH_FILE)

.PHONY: unpatch
unpatch: $(K8S_DIR)
	@echo "* Reseting Kubernetes repo"
	(cd k8s && git reset --hard)
	rm -f $(SENTINEL_PATCH) $(SENTINEL_BUILD) $(SENTINEL_VENDOR)

.PHONY: vendor
vendor: $(K8S_DIR) $(SENTINEL_VENDOR)

$(SENTINEL_VENDOR):
	@echo "* Installing trace point provider..."
	(cd $(K8S_DIR) && go get github.com/BenjaminSaintCyr/k8s-lttng-tpp)
	(cd $(K8S_DIR) && go mod vendor)
	(cd $(K8S_DIR) && git checkout -- vendor/k8s.io)
	@touch $(SENTINEL_VENDOR)

.PHONY: tracer
tracer: $(TPP_DIR)/k8s-tpp.o

$(TPP_DIR)/k8s-tpp.o:
	@echo "* Building the trace point provider..."
	(cd $(TPP_DIR) && make clean && make)

# Deploy

.PHONY: setup-vms
setup-vms: $(K8S_ZIP) $(PATCH_FILE) Makefile
	@echo "* Setting up the vms"
	vagrant up
	vagrant scp Makefile .
	vagrant scp $(PATCH_FILE) .
	vagrant scp $(K8S_ZIP) .
	vagrant ssh -- make build-k8s

.PHONY: deploy-k8s
deploy-k8s:
	@echo "* Distributing kubernetes binaries to vms"
	./deploy_k8s.sh

.PHONY: clean
clean:
	rm -rf $(K8S_DIR) $(CACHE_DIR)
	vagrant destroy -f

# Experiment
.PHONY: trace
trace:
	-lttng-sessiond --daemonize
	lttng create kube-tracing
	lttng enable-channel --kernel kube-channel --num-subbuf=4 --subbuf-size=32M
	lttng enable-channel --userspace kube-channel --num-subbuf=4 --subbuf-size=32M
	lttng enable-event -u -a -c kube-channel
	lttng add-context -u -t vpid -t vtid -t procname
	lttng enable-event -k -c kube-channel --tracepoint sched* #sched
	lttng enable-event -k -c kube-channel --tracepoint irq* # irq
	lttng enable-event -k -c kube-channel --syscall read,write,open,close,newstat,newfstat,newlstat,openat # file access
	lttng enable-event -k -c kube-channel --syscall mount,umount # mount
	lttng enable-event -k -c kube-channel --syscall timer*,clock* # timer/clock
	lttng enable-event -k -c kube-channel --syscall unshare,setns # namespace
	lttng add-context -k -t pid -t tid -t procname
	lttng add-context -k -t vpid -t vtid -t cgroup_ns # namespace context
	lttng start

