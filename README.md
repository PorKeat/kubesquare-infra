# 📖 Complete Kubernetes HA, Cilium & KubeSphere Manual Setup Guide

A complete, human-readable learning and reference manual designed for manual step-by-step setup, understanding each component, and future deployments.

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Step 1: Linux Node Preparation (All Nodes)](#step-1-linux-node-preparation-all-nodes)
3. [Step 2: Kubernetes HA Cluster via KubeKey v4](#step-2-kubernetes-ha-cluster-via-kubekey-v4)
4. [Step 3: Cilium eBPF CNI & Hubble Dashboard](#step-3-cilium-ebpf-cni--hubble-dashboard)
5. [Step 4: KubeSphere v4 Enterprise Dashboard](#step-4-kubesphere-v4-enterprise-dashboard)
6. [Essential Verification & Diagnostic Commands](#essential-verification--diagnostic-commands)

---

## 1. Architecture Overview

```text
               +-------------------------------------------+
               |       HA Control Plane (kube-vip)         |
               +---------------------+---------------------+
                                     |
         +---------------------------+---------------------------+
         |                           |                           |
         v                           v                           v
+-----------------+         +-----------------+         +-----------------+
|     master1     | <=====> |     master2     | <=====> |     master3     |
|   10.148.0.3    |         |   10.148.0.4    |         |   10.148.0.5    |
+-----------------+         +-----------------+         +-----------------+
         |                           |                           |
         +---------------------------+---------------------------+
                                     |
               +---------------------+---------------------+
               |   Cilium eBPF High-Speed Network Mesh     |
               |       (Hubble Flow UI Dashboard)          |
               +---------------------+---------------------+
                                     |
               +---------------------+---------------------+
               |    KubeSphere v4 Enterprise Console       |
               |        (Web Management Platform)          |
               +-------------------------------------------+
```

---

## Step 1: Linux Node Preparation (All Nodes)

> **Where to run**: Run these commands on **every node** (`master1`, `master2`, `master3`).

### 1.1 Disable Swap Memory
Kubernetes memory management requires Linux swap memory to be completely disabled.

```bash
# Disable swap immediately
sudo swapoff -a

# Persist swap disable across reboots
sudo sed -i '/swap/s/^/#/' /etc/fstab
```

### 1.2 Enable Linux Kernel Modules
Kubernetes and container runtimes (containerd) require the `overlay` filesystem and `br_netfilter` kernel modules.

```bash
# Load kernel modules into current session
sudo modprobe overlay
sudo modprobe br_netfilter

# Persist modules across system reboots
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

### 1.3 Configure Sysctl Networking Parameters
Enable IP packet forwarding and bridge netfilter inspection:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl settings immediately
sudo sysctl --system
```

### 1.4 Install Required System Packages
```bash
sudo apt update
sudo apt install -y socat conntrack ipset curl openssl
```

---

## Step 2: Kubernetes HA Cluster via KubeKey v4

> **Where to run**: Run these steps **only on `master1`** (`10.148.0.3`).

### 2.1 Download KubeKey Binary
```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
```

### 2.2 Define Your Inventory (`inventory.yaml`)
Create `inventory.yaml` to specify your servers and SSH access:

```yaml
apiVersion: kubekey.kubesphere.io/v1
kind: Inventory
metadata:
  name: default
spec:
  hosts:
    master1:
      connector:
        type: local
      internal_ipv4: 10.148.0.3
    master2:
      connector:
        type: ssh
        host: 10.148.0.4
        port: 22
        user: alexkgm2412
        private_key_path: /home/alexkgm2412/.ssh/id_rsa
      internal_ipv4: 10.148.0.4
    master3:
      connector:
        type: ssh
        host: 10.148.0.5
        port: 22
        user: alexkgm2412
        private_key_path: /home/alexkgm2412/.ssh/id_rsa
      internal_ipv4: 10.148.0.5
  groups:
    k8s_cluster:
      groups:
        - kube_control_plane
        - kube_worker
    kube_control_plane:
      hosts:
        - master1
        - master2
        - master3
    kube_worker:
      hosts:
        - master1
        - master2
        - master3
    etcd:
      hosts:
        - master1
        - master2
        - master3
```

### 2.3 Define Cluster Settings (`config.yaml`)
Create `config.yaml` with your Kubernetes version and resource reservation:

```yaml
apiVersion: kubekey.kubesphere.io/v1
kind: Config
spec:
  zone: ""
  kubernetes:
    kube_version: v1.34.3
    helm_version: v3.18.5
    sandbox_image:
      tag: "3.10.1"
    extra_args:
      kubelet:
        - --system-reserved=cpu=500m,memory=1Gi
        - --kube-reserved=cpu=300m,memory=500Mi
        - --eviction-hard=memory.available<500Mi,nodefs.available<10%
    control_plane_endpoint:
      type: local
  etcd:
    etcd_version: v3.6.5
  cri:
    container_manager: containerd
    crictl_version: v1.34.0
  cni:
    type: cilium
    multi_cni: none
    cilium_version: 1.19.1
```

### 2.4 Execute Cluster Creation
```bash
./kk create cluster -i inventory.yaml --config config.yaml
```

---

## Step 3: Cilium eBPF CNI & Hubble Dashboard

> **Where to run**: Run on `master1`.

Cilium manages pod IP addresses, high-speed packet routing, and network security policies directly in the Linux kernel via eBPF.

### 3.1 Install Cilium via Helm
```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium --version 1.16.1 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set k8sServiceHost=10.148.0.3 \
  --set k8sServicePort=6443 \
  --set hubble.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.relay.enabled=true
```

### 3.2 Access Hubble Flow Map UI
```bash
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 --address 0.0.0.0
```
* **URL**: `http://<YOUR_MASTER1_IP>:12000` (or `http://localhost:12000`)

---

## Step 4: KubeSphere v4 Enterprise Dashboard

> **Where to run**: Run on `master1`.

KubeSphere provides a web console for visual cluster management, workload deployment, logs, and multi-tenant workspaces.

### 4.1 Install KubeSphere Core v4
```bash
helm upgrade --install -n kubesphere-system --create-namespace \
  ks-core oci://hub.kubesphere.com.cn/kse/ks-core
```

### 4.2 Grant Required RBAC Role Binding
```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ks-apiserver-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: ks-apiserver
  namespace: kubesphere-system
EOF
```

### 4.3 Access KubeSphere Console
* **Direct Web URL**: `http://<YOUR_MASTER1_IP>:30880`
* **Local SSH Tunnel**: `ssh -L 30880:127.0.0.1:30880 master1` ➡️ Open `http://localhost:30880`
* **Default Login**:
  * **Username**: `admin`
  * **Password**: `P@88w0rd`

---

## Essential Verification & Diagnostic Commands

```bash
# 1. Verify all 3 master nodes are in 'Ready' status
kubectl get nodes -o wide

# 2. Check all cluster pods across namespaces
kubectl get pods -A

# 3. Check Cilium health & eBPF maps
kubectl -n kube-system exec -ti ds/cilium -- cilium status

# 4. Check KubeSphere backend components
kubectl get pods -n kubesphere-system
```

---

## 🧹 Cluster Reset / Teardown (When you want to start fresh)

To completely wipe and clean the cluster nodes:

```bash
./kk delete cluster -i inventory.yaml --config config.yaml
```
