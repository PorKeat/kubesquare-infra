# 02 - Cluster Installation (KubeKey v4)

KubeKey v4 uses two dedicated files:
1. **`inventory.yaml`**: Defines node IPs, SSH connections, and host role groups (`kube_control_plane`, `etcd`, `kube_worker`).
2. **`config.yaml`**: Defines Kubernetes parameters, Cilium CNI, Containerd CRI, and resource reservations.

---

### 1. The Inventory (`inventory.yaml`)

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
      hosts: []
    etcd:
      hosts:
        - master1
        - master2
        - master3
```

---

### 2. The Configuration (`config.yaml`)

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
    # ~20% compute resource reservation for system & K8s daemons
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
  # Cilium eBPF CNI & Security Policies
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

### 3. Run Cluster Installation (Run on `master1`)

```bash
# 1. Clean previous single-node cluster
./kk delete cluster -i inventory.yaml --config config.yaml

# 2. Launch the 3-node HA installation
./kk create cluster -i inventory.yaml --config config.yaml
```

---

### 4. Verify Installation

```bash
# Verify all 3 master nodes are Ready
kubectl get nodes -o wide

# Check all running pods
kubectl get pods -A
```

---

### 📚 References
* [KubeKey Official Repository](https://github.com/kubesphere/kubekey)
* [Cilium Installation via KubeKey](https://docs.cilium.io/en/stable/installation/k8s-install-helm/)
* [Kubernetes Resource Reservation Guide](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
