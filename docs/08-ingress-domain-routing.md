# 08 - Production Ingress & Domain Routing

This guide explains how to expose Kubernetes web applications and consoles with custom domain names and automated Let's Encrypt SSL/TLS certificates via Traefik.

---

## 🌐 Live Production Example: `ks.sengporkeat.com`

* **Public URL**: [https://ks.sengporkeat.com](https://ks.sengporkeat.com)
* **Backend Service**: `ks-console.kubesphere-system:80`
* **TLS Issuer**: `letsencrypt-prod` (Automated HTTP-01 challenge)

---

## 🛠️ Step-by-Step Guide to Expose Any Service with a Domain

### 1. Configure DNS `A` Record
In your Domain Registrar (Cloudflare, GoDaddy, Namecheap):
* **Record Type**: `A`
* **Name / Subdomain**: `app` (e.g. `app.yourdomain.com`)
* **Target IP**: `34.21.251.93` (or your master public IP)
* **Proxy Status**: DNS Only (Gray Cloud if on Cloudflare)

---

### 2. Standard Production Ingress Template

Create `app-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - app.yourdomain.com
      secretName: app-tls-cert
  rules:
    - host: app.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service-name
                port:
                  number: 80
```

Apply to the cluster:
```bash
kubectl apply -f app-ingress.yaml
```

---

### 3. Verify Certificate Issuance

```bash
# Check Ingress
kubectl get ingress -A

# Check Let's Encrypt Certificate
kubectl get certificate -A
```
Once `READY` is `True`, your application is accessible securely over `https://app.yourdomain.com` with a valid SSL padlock!
