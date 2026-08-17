# 03 - Distributed Storage (Longhorn)

[Longhorn](https://longhorn.io/) is an open-source, cloud-native distributed block storage system designed for Kubernetes by CNCF.

---

### 1. Install Longhorn via Helm (Run on `master1`)

According to the [Longhorn Official Helm Installation Guide](https://longhorn.io/docs/latest/deploy/install/install-with-helm/):

```bash
# Add official Longhorn Helm repository
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Longhorn into dedicated namespace
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.defaultDataPath="/var/lib/longhorn"
```

---

### 2. Verify Storage Installation

```bash
# Check all Longhorn controller and CSI pods are running
kubectl get pods -n longhorn-system

# Verify default storage class is created
kubectl get storageclass
```
*(Expected output should show `longhorn (default)`).*

---

### 3. Access Longhorn UI Dashboard

To inspect disk replication, volumes, and backup targets visually:

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80 --address 0.0.0.0
```
Open `http://10.148.0.3:8080` in your web browser.

---

### 📚 References
* [Longhorn Official Documentation](https://longhorn.io/docs/)
* [Longhorn Helm Chart Repository](https://github.com/longhorn/charts)
* [Longhorn Architecture & CSI Driver](https://longhorn.io/docs/latest/concepts/architecture/)
