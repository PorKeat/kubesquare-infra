# Kubesquare Infrastructure Documentation

Welcome to the **Kubesquare** HA Kubernetes Cluster Documentation. This repository provides step-by-step guides and manifests for provisioning, configuring, and maintaining an enterprise-grade Kubernetes cluster based on official upstream standards.

---

## 🏗️ Architecture Summary

* **Topology**: 3-Node High Availability Control Plane (No single point of failure)
  * `master1`: `10.148.0.3`
  * `master2`: `10.148.0.4`
  * `master3`: `10.148.0.5`
* **Cluster Installer**: [KubeKey v4 (KubeSphere)](https://github.com/kubesphere/kubekey)
* **HA Endpoint & VIP Provider**: [kube-vip](https://kube-vip.io/)
* **Container Network Interface (CNI)**: [Cilium (eBPF-based)](https://cilium.io/)
* **Container Runtime (CRI)**: [containerd](https://containerd.io/)
* **Distributed Block Storage (CSI)**: [Longhorn v1.12.1 (CNCF)](https://longhorn.io/)
* **Ingress Controller**: [Traefik Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
* **Automated TLS / SSL**: [cert-manager & Let's Encrypt](https://cert-manager.io/docs/)
* **Resource Optimization**: [Kubernetes Kubelet Resource Reservation](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/) (~20% reserved)

---

## 🛡️ What is `kube-vip` & Why is it used?

[**kube-vip**](https://kube-vip.io/) provides **High Availability (HA)** and **Virtual IP (VIP) Load Balancing** for both the Kubernetes control-plane API servers and Kubernetes `LoadBalancer` services.

### Key Features & Benefits in Kubesquare:
1. **Zero Single Point of Failure (SPOF)**:
   Instead of pointing worker nodes or `kubectl` clients to a single master IP (which would break if that node goes down), `kube-vip` publishes a single floating Virtual IP / endpoint that dynamically routes traffic to any healthy control-plane node (`master1`, `master2`, or `master3`).
2. **Raft / BGP / ARP Leader Election**:
   `kube-vip` instances run as static pods across all control-plane nodes and elect a leader. If the active leader node fails, `kube-vip` fails over to another healthy master node within milliseconds.
3. **No External Hardware Load Balancer Required**:
   Eliminates the complexity and cost of maintaining dedicated external load balancers (like F5 or cloud-specific load balancers) for control-plane HA.

---

## 📚 Documentation Index

1. [**01 - VM Prerequisites & Base Setup**](file:///Users/alexkgm/Kubesquare/docs/01-prerequisites.md)
   * SSH key exchange, swap deactivation, sysctl parameters, kernel modules (eBPF & bridge), and required storage daemons.
2. [**02 - Cluster Installation (KubeKey v4)**](file:///Users/alexkgm/Kubesquare/docs/02-cluster-install.md)
   * KubeKey v4 setup, `inventory.yaml`, `config.yaml`, and cluster provisioning steps.
3. [**03 - Distributed Storage (Longhorn)**](file:///Users/alexkgm/Kubesquare/docs/03-storage-longhorn.md)
   * iSCSI prerequisites, Longhorn Helm deployment, StorageClass verification, and UI dashboard access.
4. [**04 - Ingress & SSL (Traefik & Let's Encrypt)**](file:///Users/alexkgm/Kubesquare/docs/04-ingress-traefik-ssl.md)
   * Traefik Helm chart installation, `cert-manager` setup, and Let's Encrypt `ClusterIssuer` definition.
5. [**05 - Network Security (Cilium eBPF Policies)**](file:///Users/alexkgm/Kubesquare/docs/05-network-security-cilium.md)
   * Multi-tenancy namespace isolation rules and Cilium network policies.
6. [**06 - Understanding Cilium & eBPF (Simple Guide)**](file:///Users/alexkgm/Kubesquare/docs/06-cilium-ebpf-guide.md)
   * Plain English overview of how Cilium works, eBPF benefits, and core features.

---

## 🔗 Official Documentation References

* **Kubernetes Official Docs**: [https://kubernetes.io/docs/](https://kubernetes.io/docs/)
* **kube-vip Official Documentation**: [https://kube-vip.io/](https://kube-vip.io/)
* **KubeKey GitHub & Docs**: [https://github.com/kubesphere/kubekey](https://github.com/kubesphere/kubekey)
* **Cilium Documentation**: [https://docs.cilium.io/en/stable/](https://docs.cilium.io/en/stable/)
* **Longhorn Documentation**: [https://longhorn.io/docs/](https://longhorn.io/docs/)
* **Traefik Ingress Documentation**: [https://doc.traefik.io/traefik/](https://doc.traefik.io/traefik/)
* **cert-manager Documentation**: [https://cert-manager.io/docs/](https://cert-manager.io/docs/)
