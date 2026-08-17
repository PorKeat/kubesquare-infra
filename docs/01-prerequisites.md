# 01 - VM Prerequisites & Base Setup

Run these commands on all 3 VMs (`10.148.0.3`, `10.148.0.4`, and `10.148.0.5`) before starting cluster creation.

---

### 1. SSH Key Exchange (Crucial for Multi-Node / Cloud VMs)

Cloud VMs (GCP, AWS) disable SSH password authentication by default. Passwordless SSH key authentication from `master1` to all nodes is **mandatory** for KubeKey.

#### Step 1: Generate SSH Key on `master1` (`10.148.0.3`)
```bash
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```
*(Copy the generated public key)*

#### Step 2: Add Public Key to `master1`, `master2`, and `master3`
Run on **each** VM:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "<PASTE_COPIED_PUBLIC_KEY_HERE>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Step 3: Verify SSH Access from `master1`
Run from `master1` to verify passwordless connection and sudo access:
```bash
ssh -i ~/.ssh/id_rsa alexkgm2412@10.148.0.3 "sudo whoami"
ssh -i ~/.ssh/id_rsa alexkgm2412@10.148.0.4 "sudo whoami"
ssh -i ~/.ssh/id_rsa alexkgm2412@10.148.0.5 "sudo whoami"
```
*(Each command must output `root` without asking for a password).*

---

### 2. Disable Swap (Required by Kubernetes)
According to the [Kubernetes Production Environment Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin), swap must be disabled to ensure kubelet memory allocation guarantees.

```bash
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
```

---

### 3. Install Required Packages
Installs dependencies required by Kubernetes, Cilium eBPF, and [Longhorn OS Requirements](https://longhorn.io/docs/latest/deploy/install/):

```bash
sudo apt-get update && sudo apt-get install -y \
  socat conntrack ipset curl openssl \
  open-iscsi nfs-common cryptsetup

# Enable and start iscsid daemon (required for Longhorn CSI)
sudo systemctl enable --now iscsid
```

---

### 4. Load Kernel Modules & Configure Sysctl
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

### 📚 References
* [Kubernetes: Installing kubeadm - Before you begin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)
* [Kubernetes: Container Runtimes & Bridging](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
* [Cilium: System Requirements & Linux Kernel](https://docs.cilium.io/en/stable/operations/system_requirements/)
* [Longhorn: OS & Environment Requirements](https://longhorn.io/docs/latest/deploy/install/#installation-requirements)
