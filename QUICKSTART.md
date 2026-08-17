# 🚀 Kubesquare: Core Architecture & Setup Guide

A focused guide covering the core foundations: **KubeKey v4**, **Cilium (eBPF)**, and **KubeSphere v4**.

---

## 🏗️ 1. Node Preparation (Run on `master1`, `master2`, `master3`)

```bash
# 1. Disable swap & load networking kernel modules
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo modprobe overlay && sudo modprobe br_netfilter

# 2. Install essential networking tools
sudo apt update && sudo apt install -y socat conntrack ipset curl
```

---

## ☸️ 2. Provision Kubernetes HA Cluster (KubeKey v4)

Run only on **`master1`** (`10.148.0.3`):

```bash
# 1. Download KubeKey binary
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk

# 2. Create Cluster using your inventory and config
./kk create cluster -i inventory.yaml --config config.yaml

# 3. Verify all 3 master nodes are Ready
kubectl get nodes -o wide
```

---

## 🌐 3. Deploy Cilium CNI (eBPF) + Hubble Dashboard

Run on **`master1`**:

```bash
# 1. Add Cilium repo and install CNI with Hubble UI
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

# 2. Open Hubble Network Flow Dashboard
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 --address 0.0.0.0
# URL: http://34.21.251.93:12000 (or http://localhost:12000)
```

---

## 🖥️ 4. Deploy KubeSphere v4 Web Console

Run on **`master1`**:

```bash
# 1. Install KubeSphere Core v4 via Helm OCI
helm upgrade --install -n kubesphere-system --create-namespace \
  ks-core oci://hub.kubesphere.com.cn/kse/ks-core

# 2. Grant RBAC cluster permissions
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

# 3. Access KubeSphere Console
# URL: https://ks.sengporkeat.com (or http://34.21.251.93:30880)
# Default Login: admin / P@88w0rd
```

---

## 🚦 Essential Health Check Commands

```bash
# Check all 3 cluster nodes
kubectl get nodes -o wide

# Check Cilium eBPF status
kubectl -n kube-system exec -ti ds/cilium -- cilium status

# Check KubeSphere pods
kubectl get pods -n kubesphere-system
```
