# 02 - Cluster Installation (KubeKey v4)

KubeKey can be executed from **Option A: Master1 Node** or **Option B: Your Local Machine (Mac/Linux)**.

---

### 1. Download KubeKey

#### Option A: On `master1` (Linux)
```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
./kk version
```

#### Option B: On your Local Machine (Mac / Laptop)
```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
./kk version
```

---

### 2. Configuration (`config-sample.yaml`)

Use the configuration below. 

> 💡 **Tip for Local Laptop installs**: If running from your local machine, set `address` to the VM's **Public IP** (or private IP if on VPN) and `privateKeyPath` to your local SSH key (e.g., `~/.ssh/google_compute_engine` or `~/.ssh/id_rsa`).

```yaml
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
    # Set address to internal IP (if run from master1/VPN) or External IP (if run from laptop)
    - {name: master1, address: 10.148.0.3, internalAddress: 10.148.0.3, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
    - {name: master2, address: 10.148.0.4, internalAddress: 10.148.0.4, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
    - {name: master3, address: 10.148.0.5, internalAddress: 10.148.0.5, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
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
    # ~20% compute resource reservation for system & K8s daemons
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

### 3. Run Cluster Installation

```bash
# Optional: Clean any previous incomplete install
./kk delete cluster --config config-sample.yaml

# Launch 3-Node HA cluster installation
./kk create cluster --config config-sample.yaml
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
* [kube-vip HA Architecture](https://kube-vip.io/docs/about/architecture/)
* [Kubernetes Resource Reservation Guide](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
