# Kubernetes Instrumented Testing Environment

This repository facilitates a specialized testing environment for an instrumented version of Kubernetes, allowing for detailed performance and behavior analysis. The setup includes a custom `Makefile` for the build process, a patch file (`lttng.patch`) for instrumentation, and configurations for both single-node and multi-node Kubernetes clusters.

## Structure

- **Makefile**: Automates the Kubernetes build process with the necessary instrumentation.
- **lttng.patch**: Applies specific modifications to Kubernetes, enabling LTTng tracing capabilities.
- **single-node**: Configuration files and scripts for setting up a Kubernetes environment on a single node.
- **multi-node**: Resources and instructions for deploying a multi-node Kubernetes cluster (3 masters, 3 workers).

## Getting Started

Follow these instructions to prepare, build, and deploy your instrumented version of Kubernetes.

### Prerequisites

Ensure the following tools are installed:

- `make`
- `lttng-ust`
- `go`
- `vagrant`

### Building the Instrumented Kubernetes

You can build the instrumented Kubernetes version on your host machine or within the single-node environment.

```sh
make build-k8s
```

This command utilizes the `Makefile` and `lttng.patch` to compile Kubernetes with the necessary instrumentation.

### Setting Up the Single-Node Environment

Perform the following steps in your single-node environment:

1. Configure `containerd` to use the systemd cgroup:
```sh
cat > /etc/containerd/config.toml <<EOF
[plugins."io.containerd.grpc.v1.cri"]
  systemd_cgroup = true
EOF
```

2. Install `etcd`:
```sh
./k8s/hack/install-etcd.sh
export PATH="/home/vagrant/k8s/third_party/etcd:${PATH}"
```

3. Launch the Kubernetes cluster:
```sh
sudo swapoff -a # Ensure swap is disabled
k8s/hack/local-up-cluster.sh -O &
```

4. Set up `kubectl` to interact with the cluster:
```sh
mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /var/run/kubernetes/admin.kubeconfig $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Initiating the Multi-Node Environment

Navigate to the multi-node environment directory and set up the cluster:

```sh
cd multi-node
vagrant destroy -f # Destroys any previous environment setup
./scripts/setup     # Initiates the new environment
```

This process deploys a Kubernetes cluster across multiple virtual machines, with 3 master nodes and 3 worker nodes, ready for your testing and development.
