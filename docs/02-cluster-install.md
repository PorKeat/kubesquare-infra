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

### 2. Reset / Clean Previous Incomplete Cluster (If needed)

If an installation was previously run on a single node:

```bash
./kk delete cluster -f config-sample.yaml --force
```

---

### 3. Prepare Configuration (`config-sample.yaml`)

Ensure `config-sample.yaml` on `master1` uses `privateKeyPath: "~/.ssh/id_rsa"` for SSH key authentication:

```yaml
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
    # Master node 1 host definition (IP, internal IP, SSH username, and privateKeyPath)
    - {name: master1, address: 10.148.0.3, internalAddress: 10.148.0.3, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
    # Master node 2 host definition (IP, internal IP, SSH username, and privateKeyPath)
    - {name: master2, address: 10.148.0.4, internalAddress: 10.148.0.4, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
    # Master node 3 host definition (IP, internal IP, SSH username, and privateKeyPath)
    - {name: master3, address: 10.148.0.5, internalAddress: 10.148.0.5, user: alexkgm2412, privateKeyPath: "~/.ssh/id_rsa"}
  roleGroups:
    # Role assignment for etcd key-value datastore across all 3 nodes
    etcd:
      - master1 # Run etcd on master1
      - master2 # Run etcd on master2
      - master3 # Run etcd on master3
    # Role assignment for Kubernetes control-plane components (API server, scheduler, controller-manager)
    control-plane:
      - master1 # Run control-plane on master1
      - master2 # Run control-plane on master2
      - master3 # Run control-plane on master3
    # Dedicated worker node list (empty since all 3 nodes act as control-plane & workload nodes)
    worker: []
---
apiVersion: kubekey.kubesphere.io/v1
kind: Config
spec:
  # Download zone: set to "cn" for mainland China acceleration, leave empty for international
  zone: ""
  kubernetes:
    # Desired Kubernetes version to install
    kube_version: v1.34.3
    # Helm binary version to install
    helm_version: v3.18.5
    # Sandbox (pause) container image tag
    sandbox_image:
      tag: "3.10.1"
    # Kubelet resource reservations and eviction thresholds (~20% reserved capacity)
    extra_args:
      kubelet:
        # System-reserved compute resources for OS daemons (sshd, udev, systemd)
        - --system-reserved=cpu=500m,memory=1Gi
        # Kube-reserved compute resources for Kubernetes daemons (kubelet, containerd)
        - --kube-reserved=cpu=300m,memory=500Mi
        # Hard eviction thresholds to prevent node out-of-memory lockups
        - --eviction-hard=memory.available<500Mi,nodefs.available<10%
    # High Availability control plane endpoint configuration
    control_plane_endpoint:
      # Use kube-vip to create an active/standby virtual IP for the API servers
      type: kube-vip
      kube_vip:
        image:
          # kube-vip container image version tag
          tag: v0.7.2
  etcd:
    # etcd version to deploy
    etcd_version: v3.6.5
  image_registry:
    # Private container registry type (leave empty if not deploying a local Harbor/Docker registry)
    type: ""
    # High availability virtual IP for private image registry
    ha_vip: ""
  cri:
    # Container Runtime Interface (CRI) engine
    container_manager: containerd
    # crictl CLI utility version
    crictl_version: v1.34.0
  # Container Network Interface (CNI) configuration
  cni:
    # Network plugin type: Cilium (eBPF-based high performance CNI and security policy engine)
    type: cilium
    # Multi-CNI chaining mode (disabled)
    multi_cni: none
    # Cilium version to install
    cilium_version: 1.19.1
  # Persistent Storage Class configuration
  storage_class:
    # Local hostPath storage class (disabled in favor of Longhorn distributed storage)
    local:
      enabled: false # Do not enable local storage provisioner
      default: false # Do not mark local storage as default
    # NFS storage provisioner (disabled)
    nfs:
      enabled: false
  dns:
    # CoreDNS cluster DNS deployment
    coredns:
      image:
        tag: v1.12.1
    # NodeLocal DNSCache for local caching of DNS queries on each node
    nodelocaldns:
      enabled: true
      image:
        tag: 1.26.4
  # External offline image packages to preload (empty for online installs)
  image_manifests: []
```

---

### 4. Run Cluster Creation

Execute cluster installation from `master1`:

```bash
./kk create cluster --config config-sample.yaml
```

---

### 5. Verify Installation

```bash
# Verify all 3 nodes are in Ready status as control-plane
kubectl get nodes -o wide

# Check all system and networking pods (Cilium, CoreDNS, kube-vip)
kubectl get pods -A

# Check etcd cluster health across 3 nodes
kubectl get pods -n kube-system -o wide | grep etcd
```

---

### 📚 References
* [KubeKey GitHub & Architecture](https://github.com/kubesphere/kubekey)
* [kube-vip Control Plane Load Balancing](https://kube-vip.io/docs/about/architecture/)
* [Kubernetes: Reserve Compute Resources](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
* [Cilium Installation via KubeKey](https://docs.cilium.io/en/stable/installation/k8s-install-helm/)
