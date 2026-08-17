# Justfile for Kubesquare Infrastructure Management
# Install just: https://github.com/casey/just

# Default recipe: show available commands
default:
    @just --list

# ==============================================================================
# 1. CLUSTER LIFECYCLE (KUBEKEY v4)
# ==============================================================================

# Create the 3-node HA Kubernetes cluster with Cilium eBPF
cluster-create:
    ./kk create cluster -i inventory.yaml --config config.yaml

# Clean and delete the Kubernetes cluster across all nodes
cluster-delete:
    ./kk delete cluster -i inventory.yaml --config config.yaml

# Get cluster nodes and wide network details
cluster-nodes:
    kubectl get nodes -o wide

# Get all cluster pods across all namespaces
cluster-pods:
    kubectl get pods -A

# ==============================================================================
# 2. ANSIBLE AUTOMATION
# ==============================================================================

# Provision and prepare VM pre-requisites (swap, kernel modules, sysctl, storage tools)
ansible-prepare:
    ansible-playbook -i ansible/hosts.ini ansible/prepare-nodes.yml

# Ping all nodes defined in ansible/hosts.ini
ansible-ping:
    ansible all -i ansible/hosts.ini -m ping

# ==============================================================================
# 3. STORAGE (LONGHORN v1.12.1)
# ==============================================================================

# Install or upgrade Longhorn distributed storage
longhorn-install:
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    helm install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --create-namespace \
      --version 1.12.1

# Check Longhorn pods and storageclasses
longhorn-status:
    kubectl get pods -n longhorn-system
    kubectl get storageclass

# Port-forward Longhorn web UI to localhost:8080
longhorn-ui:
    kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# ==============================================================================
# 4. INGRESS (TRAEFIK) & SSL (CERT-MANAGER)
# ==============================================================================

# Install official Traefik Ingress Controller
traefik-install:
    helm repo add traefik https://traefik.github.io/charts
    helm repo update
    helm install traefik traefik/traefik \
      --namespace traefik \
      --create-namespace

# Install cert-manager from Jetstack repository
cert-manager-install:
    helm repo add jetstack https://charts.jetstack.io --force-update
    helm repo update
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --set crds.enabled=true

# Check status of Traefik and cert-manager
ingress-status:
    kubectl get pods -n traefik
    kubectl get svc -n traefik
    kubectl get pods -n cert-manager
    kubectl get clusterissuer

# ==============================================================================
# 5. SECURITY & POLICIES (CILIUM eBPF)
# ==============================================================================

# Apply Cilium namespace isolation network policies
cilium-apply-policies:
    kubectl apply -f manifests/cilium-namespace-isolation.yaml

# Check Cilium network status and endpoints
cilium-status:
    kubectl -n kube-system exec -ti ds/cilium -- cilium status
    kubectl get ciliumnetworkpolicies -A
