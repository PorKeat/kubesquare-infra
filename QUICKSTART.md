# 🚀 Kubesquare: Quick & Complete Setup Guide

A concise, step-by-step guide to provision and run the entire cluster from scratch.

---

## 🏗️ 1. Prepare VMs (Run on `master1`, `master2`, `master3`)

```bash
# Disable swap & load networking kernel modules
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo modprobe overlay && sudo modprobe br_netfilter

# Install required storage & network packages
sudo apt update && sudo apt install -y socat conntrack ipset open-iscsi nfs-common
sudo systemctl enable --now iscsid
```

---

## ☸️ 2. Install Kubernetes HA Cluster (KubeKey v4)

Run only on **`master1`** (`10.148.0.3`):

```bash
# 1. Download KubeKey
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk

# 2. Create Cluster using your inventory and config
./kk create cluster -i inventory.yaml --config config.yaml

# 3. Verify all 3 nodes are Ready
kubectl get nodes -o wide
```

---

## 🌐 3. Install Cilium CNI (eBPF) + Hubble Dashboard

Run on **`master1`**:

```bash
# 1. Install Cilium with Hubble UI enabled
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

# 2. Open Hubble UI Dashboard in your browser
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 --address 0.0.0.0
# URL: http://34.21.251.93:12000
```

---

## 🖥️ 4. Install KubeSphere v4 Web Console

Run on **`master1`**:

```bash
# 1. Install KubeSphere Core v4
helm upgrade --install -n kubesphere-system --create-namespace \
  ks-core oci://hub.kubesphere.com.cn/kse/ks-core

# 2. Grant required RBAC permissions
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

## 💾 5. Install Longhorn Distributed Storage (Optional)

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.12.1
```

---

## 🚦 Quick Commands Cheat Sheet

| Task | Command |
| :--- | :--- |
| **Check Cluster Nodes** | `kubectl get nodes -o wide` |
| **Check Cilium Network** | `kubectl -n kube-system exec -ti ds/cilium -- cilium status` |
| **Check KubeSphere Pods** | `kubectl get pods -n kubesphere-system` |
| **Check Storage Class** | `kubectl get storageclass` |
| **Open KubeSphere via SSH** | `ssh -L 30880:127.0.0.1:30880 master1` |
