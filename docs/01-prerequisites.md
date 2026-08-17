# 01 - VM Prerequisites & Base Setup

Run these commands on all 3 VMs (`10.148.0.3`, `10.148.0.4`, and `10.148.0.5`) before starting cluster creation.

---

### 1. Disable Swap (Required by Kubernetes)
According to the [Kubernetes Production Environment Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin), swap must be disabled to ensure kubelet memory allocation guarantees.

```bash
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
```

---

### 2. Install Required Packages
Installs dependencies required by Kubernetes, Cilium eBPF, and [Longhorn OS Requirements](https://longhorn.io/docs/latest/deploy/install/):

```bash
sudo apt-get update && sudo apt-get install -y \
  socat conntrack ipset curl openssl \
  open-iscsi nfs-common cryptsetup

# Enable and start iscsid daemon (required for Longhorn CSI)
sudo systemctl enable --now iscsid
```

---

### 3. Load Kernel Modules & Configure Sysctl
Required for [Cilium System Requirements](https://docs.cilium.io/en/stable/operations/system_requirements/) and [Kubernetes Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/):

```bash
# Load kernel modules immediately
sudo modprobe overlay
sudo modprobe br_netfilter

# Persist kernel modules across reboots
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Apply sysctl network parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

---

### 4. Verify Sudo Permissions
Ensure the deployment user has non-interactive or working sudo privileges:
```bash
sudo whoami
# Output must be: root
```

---

### 📚 References
* [Kubernetes: Installing kubeadm - Before you begin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)
* [Kubernetes: Container Runtimes & Bridging](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
* [Cilium: System Requirements & Linux Kernel](https://docs.cilium.io/en/stable/operations/system_requirements/)
* [Longhorn: OS & Environment Requirements](https://longhorn.io/docs/latest/deploy/install/#installation-requirements)
