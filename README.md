# Kubesquare Infrastructure Documentation (2026 Production Standard)

Welcome to the **Kubesquare** HA Kubernetes Cluster Documentation. This repository provides end-to-end guides and production-grade manifests for provisioning, managing, and securing a high-availability Kubernetes cluster based on official upstream standards.

---

## 🏗️ 2026 Production Architecture

* **Topology**: 3-Node High Availability Control Plane (Zero Single Point of Failure)
  * `master1`: `10.148.0.3`
  * `master2`: `10.148.0.4`
  * `master3`: `10.148.0.5`
* **Kubernetes Version**: `v1.34.3` (Latest stable control plane)
* **Cluster Provisioner**: [KubeKey v4.0.6 (KubeSphere)](https://github.com/kubesphere/kubekey)
* **HA Virtual IP / Endpoint**: [kube-vip v0.7.2](https://kube-vip.io/)
* **Container Network Interface (CNI)**: [Cilium v1.16.1 (eBPF-powered routing & security)](https://cilium.io/)
* **Container Runtime (CRI)**: [containerd v1.7.13](https://containerd.io/)
* **Distributed Block Storage (CSI)**: [Longhorn v1.12.1 (CNCF Distributed Storage)](https://longhorn.io/)
* **Ingress Controller**: [Traefik v3.7.10 (Traefik Labs)](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
* **Automated TLS / SSL**: [cert-manager v1.21.1 & Let's Encrypt Production ACME](https://cert-manager.io/docs/)
* **Resource Optimization**: 20% system & K8s compute reservation via `kubelet`

---

## 🛡️ Control Plane High Availability: `kube-vip`

[**kube-vip**](https://kube-vip.io/) provides **Virtual IP (VIP) Load Balancing** and **Automated Failover** across `master1`, `master2`, and `master3`:
* **Sub-second Leader Election**: If the active leader master node goes down, `kube-vip` automatically transfers the virtual IP to another healthy node.
* **No External LB Required**: Eliminates external hardware load balancers and extra cloud costs while maintaining strict HA.

---

## 📚 Official Documentation Index

1. [**01 - VM Prerequisites & Base Setup**](file:///Users/alexkgm/Kubesquare/docs/01-prerequisites.md)
   * SSH key distribution, swap deactivation, sysctl parameters, kernel modules (eBPF & bridge), and storage dependencies.
2. [**02 - Cluster Installation (KubeKey v4)**](file:///Users/alexkgm/Kubesquare/docs/02-cluster-install.md)
   * Official dual-manifest structure (`inventory.yaml` and `config.yaml`), installation, and reset commands.
3. [**03 - Distributed Storage (Longhorn v1.12.1)**](file:///Users/alexkgm/Kubesquare/docs/03-storage-longhorn.md)
   * Longhorn Helm deployment, default StorageClass configuration, and volume replication.
4. [**04 - Ingress & SSL (Traefik v3 & Let's Encrypt)**](file:///Users/alexkgm/Kubesquare/docs/04-ingress-traefik-ssl.md)
   * Traefik Labs Helm deployment, `cert-manager` setup, and Let's Encrypt production `ClusterIssuer`.
5. [**05 - Network Security (Cilium eBPF Policies)**](file:///Users/alexkgm/Kubesquare/docs/05-network-security-cilium.md)
   * Multi-tenancy namespace isolation rules and eBPF network filtering.
6. [**06 - Understanding Cilium & eBPF (Simple Guide)**](file:///Users/alexkgm/Kubesquare/docs/06-cilium-ebpf-guide.md)
   * Plain English explanation of Cilium CNI, eBPF benefits, and Hubble UI network flow inspection.
7. [**07 - Web Dashboards Guide**](file:///Users/alexkgm/Kubesquare/docs/07-dashboards-guide.md)
   * Complete access commands, port-forwarding, and tokens for Hubble UI, Longhorn Dashboard, and Kubernetes Dashboard.

---

## 🔗 Official Upstream References

* **Kubernetes Documentation**: [https://kubernetes.io/docs/](https://kubernetes.io/docs/)
* **KubeKey GitHub & Release Notes**: [https://github.com/kubesphere/kubekey](https://github.com/kubesphere/kubekey)
* **kube-vip Architecture**: [https://kube-vip.io/](https://kube-vip.io/)
* **Cilium Official Documentation**: [https://docs.cilium.io/en/stable/](https://docs.cilium.io/en/stable/)
* **Longhorn Official Documentation**: [https://longhorn.io/docs/](https://longhorn.io/docs/)
* **Traefik Ingress Documentation**: [https://doc.traefik.io/traefik/](https://doc.traefik.io/traefik/)
* **cert-manager Documentation**: [https://cert-manager.io/docs/](https://cert-manager.io/docs/)
