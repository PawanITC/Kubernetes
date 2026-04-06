# Kubernetes Microservices Platform

[![CI](https://github.com/PawanITC/Kubernetes/actions/workflows/ci.yml/badge.svg)](https://github.com/PawanITC/Kubernetes/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Java](https://img.shields.io/badge/Java-17-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2-green)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue)
![Helm](https://img.shields.io/badge/Helm-3.x-blue)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-orange)

A production-ready GitHub repository template featuring two Java microservices deployable to **Docker Desktop** (local) and **production Kubernetes** clusters. Includes full GitOps, networking, security, scaling, monitoring, and CI/CD.

---

## Architecture

```
                        ┌─────────────────────────────────────┐
  Internet              │         Kubernetes Cluster          │
     │                  │                                     │
     ▼                  │   ┌───────────────────────────┐    │
┌─────────┐   HTTPS     │   │      ingress-nginx        │    │
│ Browser │────────────►│   │   (Ingress Controller)    │    │
└─────────┘             │   └────────┬────────┬─────────┘    │
                        │            │        │               │
                        │            ▼        ▼               │
                        │   ┌──────────┐  ┌──────────────┐   │
                        │   │  user-   │  │   order-     │   │
                        │   │ service  │◄─│   service    │   │
                        │   │ :8081    │  │   :8082      │   │
                        │   └────┬─────┘  └──────┬───────┘   │
                        │        │               │            │
                        │        ▼               ▼            │
                        │   ┌─────────────────────────┐      │
                        │   │       PostgreSQL DB      │      │
                        │   │  (prod) / H2 (local)    │      │
                        │   └─────────────────────────┘      │
                        │                                     │
                        │   ┌──────────┐  ┌──────────────┐   │
                        │   │Prometheus│  │   ArgoCD     │   │
                        │   │+ Grafana │  │   (GitOps)   │   │
                        │   └──────────┘  └──────────────┘   │
                        └─────────────────────────────────────┘
```

---

## Repository Structure

```
Kubernetes/
├── services/
│   ├── user-service/          # Spring Boot 3.2 — User management REST API
│   └── order-service/         # Spring Boot 3.2 — Order management (calls user-service)
├── k8s/
│   ├── base/                  # Kustomize base manifests (namespace, deployments, services)
│   ├── overlays/
│   │   ├── local/             # Docker Desktop — H2 DB, single replica, local images
│   │   └── production/        # Production — PostgreSQL, 3 replicas, HPA, TLS
│   ├── networking/            # NetworkPolicies (zero-trust micro-segmentation)
│   ├── security/              # RBAC, PodDisruptionBudgets, Secrets guidance
│   └── monitoring/            # Prometheus ServiceMonitors
├── helm/
│   ├── user-service/          # Full parameterized Helm chart
│   └── order-service/         # Full parameterized Helm chart
├── argocd/
│   ├── project.yaml           # ArgoCD AppProject
│   ├── app-of-apps.yaml       # Parent application (manages child apps)
│   └── apps/                  # Child ArgoCD Applications (prod + local)
├── scripts/
│   ├── setup-local.sh         # One-command local setup
│   ├── teardown-local.sh      # Clean up local resources
│   ├── build-images.sh        # Build + push Docker images
│   ├── setup-argocd.sh        # Install ArgoCD + deploy app-of-apps
│   └── port-forward.sh        # Port-forward services for direct access
├── .github/workflows/
│   ├── ci.yml                 # Test → Build → Push → Scan
│   └── cd.yml                 # Deploy to production
└── docs/
    └── KUBERNETES_COMPLETE_GUIDE.md  # 15,000+ word end-to-end Kubernetes guide
```

---

## Quick Start — Local (Docker Desktop)

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with **Kubernetes enabled**
- `kubectl`, `helm`, `kustomize`
- Java 17 + Maven (for local development without Docker)

### 1. Enable Kubernetes in Docker Desktop
`Settings → Kubernetes → Enable Kubernetes → Apply & Restart`

### 2. Run the setup script
```bash
chmod +x scripts/*.sh
./scripts/setup-local.sh
```

This will:
- Build Docker images locally
- Install NGINX Ingress Controller
- Deploy both services with Kustomize
- Print access URLs

### 3. Add hosts entry
```bash
sudo sh -c 'echo "127.0.0.1 microservices.local" >> /etc/hosts'
```

### 4. Test the APIs
```bash
# Create a user
curl -X POST http://microservices.local/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Jane","lastName":"Doe","email":"jane@example.com"}'

# Create an order
curl -X POST http://microservices.local/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productName":"Laptop","quantity":1,"price":999.99,"shippingAddress":"123 Main St"}'

# List all orders
curl http://microservices.local/api/v1/orders
```

### 5. Access Swagger UI
- User Service: http://microservices.local/user-service/swagger-ui/index.html
- Order Service: http://microservices.local/order-service/swagger-ui/index.html

---

## Quick Start — Helm (Alternative to Kustomize)

```bash
# Create namespace
kubectl create namespace microservices

# Deploy user-service
helm upgrade --install user-service ./helm/user-service \
  -f helm/user-service/values-local.yaml \
  -n microservices

# Deploy order-service
helm upgrade --install order-service ./helm/order-service \
  -f helm/order-service/values-local.yaml \
  -n microservices
```

---

## Services

| Service | Port | Base Path | Swagger UI | Database |
|---------|------|-----------|------------|----------|
| user-service | 8081 | `/api/v1/users` | `/swagger-ui.html` | H2 (local) / PostgreSQL (prod) |
| order-service | 8082 | `/api/v1/orders` | `/swagger-ui.html` | H2 (local) / PostgreSQL (prod) |

### user-service Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users` | List all users (optional `?status=ACTIVE`) |
| GET | `/api/v1/users/{id}` | Get user by ID |
| GET | `/api/v1/users/email/{email}` | Get user by email |
| POST | `/api/v1/users` | Create user |
| PUT | `/api/v1/users/{id}` | Update user |
| DELETE | `/api/v1/users/{id}` | Delete user |

### order-service Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/orders` | List all orders |
| GET | `/api/v1/orders/{id}` | Get order by ID |
| GET | `/api/v1/orders/user/{userId}` | Get orders by user |
| POST | `/api/v1/orders` | Create order (validates user exists) |
| PUT | `/api/v1/orders/{id}/status` | Update order status |
| PUT | `/api/v1/orders/{id}/cancel` | Cancel order |
| DELETE | `/api/v1/orders/{id}` | Delete order |

---

## Production Deployment

### Prerequisites
- Kubernetes cluster (EKS, GKE, AKS, or bare metal)
- NGINX Ingress Controller installed
- cert-manager installed (for TLS)
- PostgreSQL databases provisioned
- Secrets created in cluster

### Deploy with Kustomize
```bash
# Create secrets (use External Secrets Operator in real production)
kubectl create secret generic user-service-secret \
  --from-literal=DB_USERNAME=myuser \
  --from-literal=DB_PASSWORD=mysecret \
  -n microservices

kubectl create secret generic order-service-secret \
  --from-literal=DB_USERNAME=myuser \
  --from-literal=DB_PASSWORD=mysecret \
  -n microservices

# Deploy
kubectl apply -k k8s/overlays/production
```

### Deploy with Helm
```bash
helm upgrade --install user-service ./helm/user-service \
  -f helm/user-service/values-production.yaml \
  --set image.tag=$IMAGE_TAG \
  -n microservices

helm upgrade --install order-service ./helm/order-service \
  -f helm/order-service/values-production.yaml \
  --set image.tag=$IMAGE_TAG \
  -n microservices
```

---

## GitOps with ArgoCD

```bash
# Install ArgoCD and deploy all apps
./scripts/setup-argocd.sh
```

This installs ArgoCD and creates the app-of-apps pattern. ArgoCD will then automatically sync all services from git.

See `argocd/` directory for Application and AppProject manifests.

---

## Security Features

- **Non-root containers** — all containers run as UID 1001
- **Read-only root filesystem** — prevents container filesystem writes (production)
- **Capability dropping** — all Linux capabilities dropped (`CAP_*: drop ALL`)
- **seccomp profiles** — `RuntimeDefault` seccomp profile applied
- **RBAC** — least-privilege ServiceAccounts with Role/RoleBinding per service
- **NetworkPolicies** — zero-trust: default deny all, explicit allow rules
- **PodDisruptionBudgets** — ensures availability during maintenance
- **No automounted service account tokens** — `automountServiceAccountToken: false`
- **Secrets management guidance** — External Secrets Operator / Sealed Secrets

---

## Scaling

Both services are configured with:
- **HPA** (HorizontalPodAutoscaler): min 3 / max 10 replicas in production
- **CPU target**: 70% utilization
- **Memory target**: 80% utilization
- **PodAntiAffinity**: spreads pods across different nodes
- **TopologySpreadConstraints**: spreads pods across availability zones

---

## Monitoring

Services expose Prometheus metrics at `/actuator/prometheus`.

To scrape metrics (requires Prometheus Operator):
```bash
kubectl apply -f k8s/monitoring/servicemonitors.yaml
```

Key metrics available:
- `http_server_requests_seconds` — request latency and rate
- `jvm_memory_used_bytes` — JVM memory usage
- `hikaricp_connections_active` — database connection pool
- `process_cpu_usage` — CPU usage

---

## CI/CD Pipeline

| Stage | Trigger | Action |
|-------|---------|--------|
| Test | PR / push | `mvn test` for both services |
| Helm Lint | PR / push | `helm lint` both charts |
| Validate Manifests | PR / push | `kustomize build` both overlays |
| Build & Push | Push to main | Build Docker images → push to GHCR |
| Security Scan | After push | Trivy vulnerability scan → GitHub Security |
| Deploy | After CI success | Update image tag → `kubectl apply` |

---

## Troubleshooting

```bash
# Check pod status
kubectl get pods -n microservices

# View pod logs
kubectl logs -f deploy/user-service -n microservices

# Describe a failing pod
kubectl describe pod <pod-name> -n microservices

# Check events
kubectl get events -n microservices --sort-by='.metadata.creationTimestamp'

# Test service connectivity
kubectl run debug --image=curlimages/curl --restart=Never --rm -it -- \
  curl http://user-service.microservices.svc.cluster.local/actuator/health

# Port-forward for direct access
./scripts/port-forward.sh
```

See [docs/KUBERNETES_COMPLETE_GUIDE.md](docs/KUBERNETES_COMPLETE_GUIDE.md) for the complete troubleshooting guide and a full end-to-end Kubernetes tutorial.

---

## Helm — Package Manager for Kubernetes

### The Problem Helm Solves

Deploying even a single microservice to Kubernetes requires many YAML files: a Deployment, a Service, a ConfigMap, an Ingress, an HPA, RBAC roles, and more. When you need to deploy the same service to three environments (local, staging, production), you end up copy-pasting those files and manually editing hostnames, replica counts, image tags, and resource limits. One typo breaks production. Helm solves this by turning your Kubernetes manifests into **parameterized templates**.

Think of Helm like a `.exe` installer for Windows — instead of manually creating folders, copying files, and editing the registry, you run one command and everything is set up correctly. Helm does the same for Kubernetes.

---

### Core Concepts

| Concept | What it is | Analogy |
|---------|-----------|---------|
| **Chart** | A directory of templates + default values | An installer package (like a `.deb` or `.exe`) |
| **Release** | One installation of a chart into a namespace | An installed program (you can install the same chart twice with different names) |
| **values.yaml** | Default configuration variables | The settings/options panel for the installer |
| **templates/** | Kubernetes YAML files with `{{ }}` placeholders | A Word mail-merge template |
| **Repository** | A collection of published charts | An app store (like `apt`, `npm`, `brew`) |

---

### What Happens Internally During `helm install`

When you run:
```bash
helm upgrade --install user-service ./helm/user-service -f values-local.yaml -n microservices
```

Helm executes these 6 steps internally:

**Step 1 — Fetch the Chart**
Helm reads the chart directory (or downloads from a repository). It finds `Chart.yaml` (metadata), `values.yaml` (defaults), and all files inside `templates/`.

**Step 2 — Merge Values**
Helm layers values in priority order (highest wins):
```
Chart defaults (values.yaml)
    ↓ overridden by
values-local.yaml (passed via -f flag)
    ↓ overridden by
--set flags on the command line
```
The result is one merged map of key-value pairs used for rendering.

**Step 3 — Render Templates (Go Template Engine)**
Helm uses Go's `text/template` engine to substitute `{{ }}` placeholders with real values.

Example template (`templates/deployment.yaml`):
```yaml
replicas: {{ .Values.replicaCount }}
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
```

With `values.yaml`:
```yaml
replicaCount: 1
image:
  repository: ghcr.io/pawanITC/user-service
  tag: latest
```

Helm renders this to:
```yaml
replicas: 1
image: ghcr.io/pawanITC/user-service:latest
```

You can also use logic in templates:
```yaml
{{- if .Values.ingress.enabled }}
# This entire block is included only if ingress.enabled = true
apiVersion: networking.k8s.io/v1
kind: Ingress
...
{{- end }}
```

**Step 4 — Validate**
The rendered YAML is validated against the Kubernetes API server schema. If a field is wrong (e.g., `replicas: "one"` instead of `replicas: 1`), Helm rejects it before applying anything.

**Step 5 — Apply to Kubernetes**
Helm sends all the rendered manifests to the Kubernetes API server in dependency order (Namespace → ConfigMap → ServiceAccount → Deployment → Service → Ingress).

**Step 6 — Store the Release as a Secret**
This is what makes Helm special. After a successful install, Helm serializes the entire rendered state (all YAML files) into a Kubernetes Secret in the same namespace:

```bash
kubectl get secrets -n microservices
# NAME                           TYPE
# sh.helm.release.v1.user-service.v1   helm.sh/release.v1
# sh.helm.release.v1.user-service.v2   helm.sh/release.v1  ← after upgrade
```

Each upgrade creates a new versioned Secret. This is how `helm rollback` works — it re-applies the YAML from a previous Secret.

---

### How Helm Tracks State (vs `kubectl apply`)

| Feature | `kubectl apply` | `helm install` |
|---------|----------------|---------------|
| State tracking | None (stateless) | Stores full release history as Secrets |
| Rollback | Manual (`kubectl rollout undo`) | `helm rollback user-service 1` |
| Diff before apply | Not built-in | `helm diff upgrade` (plugin) |
| Delete all resources | Must track each resource manually | `helm uninstall user-service` removes everything |
| Multi-environment | Separate files per env | One chart + separate values files |
| Atomic upgrades | No (partial apply possible) | `--atomic` flag rolls back on failure |

---

### What `ingress-nginx` Chart Actually Installs

When you run:
```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx
```

Helm deploys ~15 Kubernetes resources in one command:

```
Namespace:            ingress-nginx
ServiceAccount:       ingress-nginx
ClusterRole:          ingress-nginx         ← permission to watch Ingress objects cluster-wide
ClusterRoleBinding:   ingress-nginx
Role:                 ingress-nginx (leader election)
RoleBinding:          ingress-nginx
ConfigMap:            ingress-nginx-controller  ← nginx.conf settings
ConfigMap:            ingress-nginx-tcp-services
Deployment:           ingress-nginx-controller  ← the actual nginx process
Service (LoadBalancer): ingress-nginx-controller  ← external IP from cloud provider
Service (ClusterIP):  ingress-nginx-controller-admission
ValidatingWebhookConfiguration:  ← validates Ingress objects before they're saved
Job:                  ingress-nginx-admission-create
Job:                  ingress-nginx-admission-patch
```

### Traffic Flow Through ingress-nginx

```
Internet
    │  HTTP/HTTPS request
    ▼
LoadBalancer Service (external IP: 203.0.113.10)
    │  forwards to pod port 80/443
    ▼
ingress-nginx Controller Pod (runs NGINX process)
    │  reads all Ingress objects in the cluster
    │  routes based on host + path rules:
    │    microservices.local/api/v1/users  → user-service:8081
    │    microservices.local/api/v1/orders → order-service:8082
    ▼
ClusterIP Service (user-service or order-service)
    │  load balances across pods
    ▼
Application Pod (Spring Boot)
```

The ingress-nginx controller continuously watches for Ingress resource changes using the Kubernetes watch API. When you create or update an Ingress object, the controller automatically regenerates its `nginx.conf` and reloads NGINX — no manual intervention needed.

---

### Useful Helm Commands

```bash
# Install or upgrade a release
helm upgrade --install <release-name> <chart-path> -f values.yaml -n <namespace>

# List all releases in a namespace
helm list -n microservices

# Show rendered templates without applying (dry-run)
helm template user-service ./helm/user-service -f values-local.yaml

# Check what will change before upgrading
helm diff upgrade user-service ./helm/user-service -f values-local.yaml   # requires helm-diff plugin

# View release history
helm history user-service -n microservices

# Roll back to a previous version
helm rollback user-service 1 -n microservices

# Uninstall a release (removes all its resources)
helm uninstall user-service -n microservices

# Download a chart from a repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm pull ingress-nginx/ingress-nginx --untar   # extracts chart locally

# Inspect default values of any chart
helm show values ingress-nginx/ingress-nginx
```

---

## License

MIT — see [LICENSE](LICENSE)
