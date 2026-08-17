# 02 - Cluster Installation (KubeKey v4)

This guide provisions the 3-node HA Kubernetes cluster using [KubeKey](https://github.com/kubesphere/kubekey) with [Cilium](https://cilium.io/) and [kube-vip](https://kube-vip.io/).

---

### 1. Download KubeKey on `master1` (`10.148.0.3`)

Download the official KubeKey installer binary:

```bash
curl -sfL https://get-kk.kubesphere.io | sh -
chmod +x kk
./kk version
```

---

### 2. Prepare Configuration (`config-sample.yaml`)

Create or update `config-sample.yaml` on `master1`:

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
    # Resource Reservation (20% reserved for OS & K8s daemons)
    extra_args:
      kubelet:
        - --system-reserved=cpu=500m,memory=1Gi
        - --kube-reserved=cpu=300m,memory=500Mi
        - --eviction-hard=memory.available<500Mi,nodefs.available<10%
    control_plane_endpoint:
      # kube-vip HA Virtual IP / Endpoint
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
  # Cilium CNI (eBPF-based networking & policies)
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

### 3. Run Cluster Creation

Execute cluster installation from `master1`:

```bash
./kk create cluster --config config-sample.yaml
```

---

### 4. Verify Installation

```bash
# Verify all nodes are in Ready status as control-plane
kubectl get nodes

# Check all system and networking pods (Cilium, CoreDNS, kube-vip)
kubectl get pods -A

# Check etcd cluster health
kubectl get pods -n kube-system -o wide | grep etcd
```

---

### 📚 References
* [KubeKey GitHub & Architecture](https://github.com/kubesphere/kubekey)
* [kube-vip Control Plane Load Balancing](https://kube-vip.io/docs/about/architecture/)
* [Kubernetes: Reserve Compute Resources](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
* [Cilium Installation via KubeKey](https://docs.cilium.io/en/stable/installation/k8s-install-helm/)
