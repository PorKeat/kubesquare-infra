# 07 - Kubernetes Web Dashboards (Hubble, Longhorn, Kubernetes Dashboard)

This guide provides instructions and access URLs for all management dashboards in your Kubesquare cluster.

---

## 🖥️ 1. Cilium (Hubble UI) - Network & Security Dashboard

Visually inspects real-time network traffic flows, pod dependencies, and security firewall rules.

```bash
# Start port-forwarding on master1 (or local laptop)
kubectl port-forward -n kube-system svc/hubble-ui 12000:80 --address 0.0.0.0
```

* **URL**: `http://34.21.251.93:12000` (or `http://localhost:12000`)
* **Login**: No authentication required.

---

## 💾 2. Longhorn Dashboard - Distributed Storage Management

Visually manages storage disks, volumes, PVCs, replicas, and backup snapshots across all 3 nodes.

```bash
# Start port-forwarding on master1 (or local laptop)
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80 --address 0.0.0.0
```

* **URL**: `http://34.21.251.93:8080` (or `http://localhost:8080`)
* **Login**: No authentication required.

---

## ☸️ 3. Official Kubernetes Web Dashboard

Full GUI for inspecting and managing all Kubernetes resources (Pods, Deployments, Services, ConfigMaps, Secrets).

```bash
# Start port-forwarding on master1 (or local laptop)
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard 8443:443 --address 0.0.0.0
```

* **URL**: `https://34.21.251.93:8443` (or `https://localhost:8443`)
* **Login**: Select **Token** and paste your cluster-admin token.

### 🔑 Get Cluster-Admin Token:
Run on `master1`:
```bash
kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d
```
