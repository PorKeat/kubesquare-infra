# 04 - Ingress & SSL (Traefik & Let's Encrypt)

This guide covers deploying [Traefik](https://doc.traefik.io/traefik/) as the Kubernetes Ingress Controller and [cert-manager](https://cert-manager.io/) with [Let's Encrypt](https://letsencrypt.org/) for automated TLS certificate provisioning and renewal.

---

### 1. Deploy Traefik Ingress Controller

Follows the [Traefik Kubernetes Ingress Guide](https://doc.traefik.io/traefik/providers/kubernetes-ingress/):

```bash
# Add Traefik Helm repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Deploy Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.web.port=80 \
  --set ports.websecure.port=443

# Verify Traefik pods & services
kubectl get pods -n traefik
kubectl get svc -n traefik
```

---

### 2. Deploy cert-manager (For Let's Encrypt SSL)

Follows the [cert-manager Installation Guide](https://cert-manager.io/docs/installation/helm/):

```bash
# Add Jetstack repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager with CustomResourceDefinitions (CRDs)
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Verify cert-manager pods
kubectl get pods -n cert-manager
```

---

### 3. Create Let's Encrypt Production ClusterIssuer

Follows [cert-manager ACME HTTP-01 Issuer Guide](https://cert-manager.io/docs/configuration/acme/http01/):

Create `cluster-issuer.yaml` (replace `your-email@example.com` with your real email):

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: traefik
```

Apply the ClusterIssuer:
```bash
kubectl apply -f cluster-issuer.yaml
```

---

### 4. Example Ingress Resource with Automatic SSL

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - app.yourcompany.com
      secretName: app-tls-cert
  rules:
    - host: app.yourcompany.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sample-app-service
                port:
                  number: 80
```

---

### 📚 References
* [Traefik Ingress Controller Documentation](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
* [cert-manager Official Documentation](https://cert-manager.io/docs/)
* [Let's Encrypt ACME Configuration with cert-manager](https://cert-manager.io/docs/configuration/acme/)
