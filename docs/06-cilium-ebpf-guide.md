# 06 - Understanding Cilium & eBPF (Simple Guide)

This guide explains what **Cilium** does in your Kubesquare cluster in simple, plain English.

---

## 💡 What is Cilium?

Think of Cilium as two things combined:
1. **The Highway**: It connects all your containers/pods together across `master1`, `master2`, and `master3` so they can talk to each other fast.
2. **The Security Guard (Firewall)**: It checks all network traffic and stops unauthorized containers from talking to each other.

---

## ⚡ Why is Cilium Special? (eBPF)

* **Old way (iptables)**: Linux had to check a long list of rules line-by-line for every single data packet. When you had thousands of pods, it became slow.
* **Cilium way (eBPF)**: Cilium runs tiny, safe programs directly inside the Linux Kernel (the core of the operating system). It routes traffic instantly with almost zero CPU overhead and ultra-low latency.

---

## 🔑 4 Core Features of Cilium in Kubesquare

### 1. Pod Networking (CNI)
* Every time you create a pod, Cilium gives it an IP address.
* It lets pods on `10.148.0.3`, `10.148.0.4`, and `10.148.0.5` talk to each other without setting up complicated network bridges.

### 2. Namespace Isolation (Security Firewall)
* By default in Kubernetes, **any pod can talk to any other pod** across any namespace.
* With Cilium Network Policies, we can lock this down:
  * Pods in `production` can only talk to other pods in `production`.
  * External traffic can only enter through the **Traefik Ingress Controller**.
  * Unauthorized pods cannot touch each other.

### 3. Smart Load Balancing
* When traffic hits a Kubernetes Service, Cilium redirects it directly to the right pod inside the Linux kernel.
* Faster than traditional `kube-proxy`.

### 4. Network Visibility (Hubble)
* You can see exactly which pods are talking to each other, which connections are allowed, and which ones are blocked in real-time.

---

## 🛠️ Helpful Commands to Check Cilium

Run these on `master1`:

```bash
# 1. Check if Cilium is healthy across all nodes
kubectl -n kube-system exec -ti ds/cilium -- cilium status

# 2. See all active network endpoints and IP addresses
kubectl -n kube-system exec -ti ds/cilium -- cilium endpoint list

# 3. See which security policies are active
kubectl get ciliumnetworkpolicies -A
```

---

## 📚 Official References
* [Cilium Official Documentation](https://docs.cilium.io/en/stable/)
* [What is eBPF? (Official Guide)](https://ebpf.io/what-is-ebpf/)
* [Cilium Network Policy Guide](https://docs.cilium.io/en/stable/security/policy/)
