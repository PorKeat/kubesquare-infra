# 04 - Ingress & SSL (Traefik & Let's Encrypt)

This guide covers deploying [Traefik](https://doc.traefik.io/traefik/) as the Kubernetes Ingress Controller and [cert-manager](https://cert-manager.io/) with [Let's Encrypt](https://letsencrypt.org/) for automated TLS certificate management directly from official sources.

---

### 1. Deploy Official Traefik Ingress Controller

According to the [Traefik Official Kubernetes Installation Guide](https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart):

```bash
# Add official Traefik Labs repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Install Traefik in dedicated namespace
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace

# Verify Traefik pods & service
kubectl get pods -n traefik
kubectl get svc -n traefik
```

---

### 2. Deploy Official cert-manager (For Let's Encrypt SSL)

According to the [cert-manager Official Installation Guide](https://cert-manager.io/docs/installation/helm/):

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

According to [cert-manager ACME HTTP-01 Configuration](https://cert-manager.io/docs/configuration/acme/http01/):

Create `cluster-issuer.yaml` (replace `your-email@example.com` with your real email address):

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

### 4. Example Ingress with Automatic SSL

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
* [Traefik Ingress Controller Official Docs](https://doc.traefik.io/traefik/)
* [Traefik Official Helm Chart Repository](https://github.com/traefik/traefik-helm-chart)
* [cert-manager Official Documentation](https://cert-manager.io/docs/)
* [Let's Encrypt ACME with cert-manager](https://cert-manager.io/docs/configuration/acme/)
