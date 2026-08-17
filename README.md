# Kubesquare: Kubernetes HA, Cilium and KubeSphere Setup Guide

A complete, clean manual setup and reference guide for deploying a high-availability Kubernetes cluster with Cilium eBPF and KubeSphere.

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Step 1: Node Preparation (All Nodes)](#step-1-node-preparation-all-nodes)
3. [Step 2: Install Kubernetes and KubeSphere (Single Command)](#step-2-install-kubernetes-and-kubesphere-single-command)
4. [Step 3: Cilium eBPF Network and Hubble Dashboard](#step-3-cilium-ebpf-network-and-hubble-dashboard)
5. [Step 4: Accessing KubeSphere Web Console](#step-4-accessing-kubesphere-web-console)
6. [Essential Verification Commands](#essential-verification-commands)
7. [Cluster Teardown / Reset](#cluster-teardown--reset)

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

## Step 1: Node Preparation (All Nodes)

Run these commands on every server (`master1`, `master2`, `master3`).

### 1.1 Disable Swap Memory
```bash
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
```

### 1.2 Enable Linux Kernel Modules
```bash
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

### 1.3 Configure Sysctl Parameters
```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 1.4 Install Required System Packages
```bash
sudo apt update
sudo apt install -y socat conntrack ipset curl openssl
```

---

## Step 2: Install Kubernetes and KubeSphere (Single Command)

Run these steps only on `master1` (`10.148.0.3`).

### 2.1 Download KubeKey
```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
```

### 2.2 Define Inventory File (`inventory.yaml`)
Create `inventory.yaml`:

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

### 2.3 Define Cluster Configuration (`config.yaml`)
Create `config.yaml`:

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

### 2.4 Run Installation with KubeSphere
```bash
./kk create cluster -i inventory.yaml --config config.yaml --with-kubesphere
```

---

## Step 3: Cilium eBPF Network and Hubble Dashboard

### 3.1 Install Cilium and Enable Hubble UI
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
URL: `http://<MASTER1_IP>:12000` (or `http://localhost:12000`)

---

## Step 4: Accessing KubeSphere Web Console

### 4.1 Access Options
* Direct Web URL: `http://<MASTER1_IP>:30880`
* Local SSH Tunnel: `ssh -L 30880:127.0.0.1:30880 master1` then open `http://localhost:30880`

### 4.2 Default Credentials
* Username: `admin`
* Password: `P@88w0rd`

---

## Essential Verification Commands

```bash
# Verify all 3 master nodes are Ready
kubectl get nodes -o wide

# Check all running pods across namespaces
kubectl get pods -A

# Check Cilium network health and eBPF status
kubectl -n kube-system exec -ti ds/cilium -- cilium status

# Check KubeSphere pods
kubectl get pods -n kubesphere-system
```

---

## Cluster Teardown / Reset

To wipe and reset the cluster nodes:

```bash
./kk delete cluster -i inventory.yaml --config config.yaml
```
