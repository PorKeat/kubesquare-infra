# Kubernetes HA Cluster Setup Guide (KubeKey v4)

## Architecture Overview

* **Node Topology**: 3 Master Nodes (Control Plane + etcd, no dedicated workers)
  * `master1`: `10.148.0.3`
  * `master2`: `10.148.0.4`
  * `master3`: `10.148.0.5`
* **Default User**: `alexkgm2412`
* **CNI**: Cilium v1.19.1 (eBPF + Network Policies for namespace isolation)
* **HA Control Plane LB**: `kube-vip`
* **Container Runtime**: `containerd`
* **Distributed Storage**: **Longhorn** (HA block storage across the 3 nodes)
* **Ingress / Web Server Controller**: **Traefik**
* **Resource Reservation**: ~20% (`kubelet` system/kube reserved)

---

## Phase 1: VM Pre-requisites & Preparation (All 3 Nodes)

Longhorn requires `iscsiadm`, `nfs-common`, `curl`, and `cryptsetup` on all nodes to mount storage.

Run these commands on **master1**, **master2**, and **master3**:

```bash
# 1. Disable swap
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# 2. Install required packages (including Longhorn & K8s dependencies)
sudo apt-get update && sudo apt-get install -y \
  socat conntrack ipset curl openssl \
  open-iscsi nfs-common cryptsetup

# Ensure iscsid service is running and enabled
sudo systemctl enable --now iscsid

# 3. Kernel modules & sysctl for Cilium/eBPF & K8s
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# 4. Verify passwordless / sudo permissions
sudo whoami
```

---

## Phase 2: Download KubeKey (On `master1`)

```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
./kk version
```

---

## Phase 3: Create Cluster Configuration

Create `config-sample.yaml` on `master1`:

```yaml
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
    - {name: master1, address: 10.148.0.3, internalAddress: 10.148.0.3, user: alexkgm2412, password: "1234"}
    - {name: master2, address: 10.148.0.4, internalAddress: 10.148.0.4, user: alexkgm2412, password: "1234"}
    - {name: master3, address: 10.148.0.5, internalAddress: 10.148.0.5, user: alexkgm2412, password: "1234"}
  roleGroups:
    etcd:
      - master1
      - master2
      - master3
    control-plane:
      - master1
      - master2
      - master3
    worker: []
---
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
      type: kube-vip
      kube_vip:
        image:
          tag: v0.7.2
  etcd:
    etcd_version: v3.6.5
  image_registry:
    type: ""
    ha_vip: ""
  cri:
    container_manager: containerd
    crictl_version: v1.34.0
  cni:
    type: cilium
    multi_cni: none
    cilium_version: 1.19.1
  storage_class:
    local:
      enabled: false
      default: false
    nfs:
      enabled: false
  dns:
    coredns:
      image:
        tag: v1.12.1
    nodelocaldns:
      enabled: true
      image:
        tag: 1.26.4
  image_manifests: []
```

---

## Phase 4: Install Base Cluster

```bash
./kk create cluster --config config-sample.yaml
```

---

## Phase 5: Verification

```bash
kubectl get nodes
kubectl get pods -A
```

---

## Phase 6: Deploy Longhorn Storage

Once the cluster is up, deploy Longhorn via Helm on `master1`:

```bash
# 1. Add Longhorn Helm Repo
helm repo add longhorn https://charts.longhorn.io
helm repo update

# 2. Install Longhorn
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.defaultDataPath="/var/lib/longhorn"

# 3. Verify Longhorn Pods & StorageClass
kubectl get pods -n longhorn-system
kubectl get storageclass
```

---

## Phase 7: Deploy Traefik Ingress Controller

Deploy Traefik to handle incoming HTTP/HTTPS traffic:

```bash
# 1. Add Traefik Helm Repo
helm repo add traefik https://traefik.github.io/charts
helm repo update

# 2. Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.web.port=80 \
  --set ports.websecure.port=443

# 3. Verify Traefik deployment
kubectl get pods -n traefik
kubectl get svc -n traefik
```
