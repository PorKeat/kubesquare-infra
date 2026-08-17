# 05 - Network Security (Cilium eBPF Policies)

[Cilium](https://cilium.io/) leverages Linux eBPF technology to provide high-performance networking, observability, and security filtering.

---

### 1. Default Namespace Isolation Policy

Follows the [Cilium Network Policy Specification](https://docs.cilium.io/en/stable/security/policy/language/):

This policy enforces strict multi-tenancy: pods inside the `production` namespace can only communicate with other pods in the same namespace, while allowing incoming traffic from Traefik Ingress and DNS resolution.

Create `namespace-isolation.yaml`:

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: isolate-namespace
  namespace: production
spec:
  endpointSelector: {} # Applies to all endpoints in this namespace
  ingress:
    # 1. Allow traffic from pods within the same namespace
    - fromEndpoints:
        - matchLabels:
            "k8s:io.kubernetes.pod.namespace": production
    # 2. Allow incoming traffic from Traefik Ingress Controller
    - fromEndpoints:
        - matchLabels:
            "k8s:io.kubernetes.pod.namespace": traefik
  egress:
    # 1. Allow internal namespace egress
    - toEndpoints:
        - matchLabels:
            "k8s:io.kubernetes.pod.namespace": production
    # 2. Allow CoreDNS traffic
    - toEndpoints:
        - matchLabels:
            "k8s:io.kubernetes.pod.namespace": kube-system
            "k8s:k8s-app": kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
    # 3. Allow internet access for outbound external APIs
    - toEntities:
        - world
```

Apply the policy:
```bash
kubectl apply -f namespace-isolation.yaml
```

---

### 2. Verify Cilium Status & Policies

```bash
# Check Cilium agents status across all nodes
kubectl -n kube-system exec -ti ds/cilium -- cilium status

# Inspect active network endpoints and policy enforcement
kubectl -n kube-system exec -ti ds/cilium -- cilium endpoint list
```

---

### 📚 References
* [Cilium Official Documentation](https://docs.cilium.io/en/stable/)
* [Cilium Network Policy Language & Rules](https://docs.cilium.io/en/stable/security/policy/language/)
* [Kubernetes Network Policies Overview](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
