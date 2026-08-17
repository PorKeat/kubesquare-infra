# 02 - Cluster Installation (KubeKey v4)

KubeKey v4 separates cluster definitions into two dedicated manifests:
* **`inventory.yaml`**: Host network connections (`connector.type: local` vs `connector.type: ssh`), IP addresses, and group mappings (`kube_control_plane`, `etcd`, `kube_worker`).
* **`config.yaml`**: Kubernetes version, Cilium CNI (eBPF), Containerd runtime, and compute resource reservations.

---

### 1. Download KubeKey on `master1` (`10.148.0.3`)

```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
./kk version
```

---

### 2. The Inventory Configuration (`inventory.yaml`)

Create `inventory.yaml` on `master1`:

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

---

### 3. The Cluster Parameters (`config.yaml`)

Create `config.yaml` on `master1`:

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

### 4. Run Cluster Creation

Execute cluster installation from `master1`:

```bash
./kk create cluster -i inventory.yaml --config config.yaml
```

---

### 5. Cluster Teardown / Reset (If needed)

To completely clean and reset the cluster nodes:

```bash
./kk delete cluster -i inventory.yaml --config config.yaml
```

---

### 6. Verify Installation

```bash
# Check all 3 master nodes are in Ready status
kubectl get nodes -o wide

# Check system and Cilium eBPF pods
kubectl get pods -A

# Check etcd cluster health
kubectl get pods -n kube-system -o wide | grep etcd
```

---

### 📚 References
* [KubeKey Official Repository & Docs](https://github.com/kubesphere/kubekey)
* [Cilium Installation via KubeKey](https://docs.cilium.io/en/stable/installation/k8s-install-helm/)
* [Kubernetes Resource Reservation Guide](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
