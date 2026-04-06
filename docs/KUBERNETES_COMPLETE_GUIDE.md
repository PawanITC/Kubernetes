# The Complete Kubernetes Guide: From Zero to Production

> **A practical, end-to-end guide** — written so that a complete beginner can follow it from page 1 to running microservices in production, while providing the technical depth that experienced engineers expect.

---

## Table of Contents

- [Part 1: Why Kubernetes Exists](#part-1-why-kubernetes-exists)
- [Part 2: Kubernetes Architecture](#part-2-kubernetes-architecture)
- [Part 3: Core Workload Objects](#part-3-core-workload-objects)
- [Part 4: Configuration and Storage](#part-4-configuration-and-storage)
- [Part 5: Networking Deep Dive](#part-5-networking-deep-dive)
- [Part 6: Security](#part-6-security)
- [Part 7: Scaling](#part-7-scaling)
- [Part 8: GitOps with ArgoCD](#part-8-gitops-with-argocd)
- [Part 9: Observability](#part-9-observability)
- [Part 10: Hands-On Walkthrough](#part-10-hands-on-walkthrough)
- [Part 11: Troubleshooting](#part-11-troubleshooting)
- [Appendix A: kubectl Cheat Sheet](#appendix-a-kubectl-cheat-sheet)
- [Appendix B: Glossary](#appendix-b-glossary)

---

# Part 1: Why Kubernetes Exists

## Chapter 1: The Problem Kubernetes Solves

### The Restaurant Kitchen Analogy

Imagine you run a small restaurant. In the beginning you have one chef, one oven, and a simple menu. Life is good.

Then your restaurant gets popular. Orders flood in. You hire five more chefs, buy four more ovens, and expand to a bigger kitchen. Now you have new problems:

- How do you make sure every chef knows what to cook?
- What happens when a chef gets sick — does the order just fail?
- How do you stop two chefs accidentally making the same dish?
- What if one oven breaks — do half your orders stop?
- How do you scale up quickly when a big party arrives, then scale back down to save costs?

**Kubernetes is the head chef and kitchen manager** that solves all these problems — but for software running in containers.

---

### The Evolution of Software Deployment

**1990s — Bare Metal**
You buy a physical server, install your application directly on it. Simple, but wasteful: one app per server means 90% of CPU is idle most of the time. If the server breaks, everything stops.

**2000s — Virtual Machines (VMs)**
You carve one physical server into several virtual servers. Better utilisation, but VMs are heavy: each one runs a full operating system (gigabytes of disk, minutes to start).

**2013 — Docker and Containers**
Containers share the host OS kernel — they start in seconds and use megabytes, not gigabytes. You can run dozens of containers on one machine. The application and all its dependencies are packaged together, so "works on my laptop" problems disappear.

**The New Problem: Orchestration**
Now you have 50 containers across 10 servers. Questions arise:
- Which server should each container run on?
- What happens when a container crashes?
- How do containers find each other on the network?
- How do you roll out a new version without downtime?
- How do you scale to 200 containers under load, then back to 50 when load drops?

**Docker alone cannot answer these questions.** This is the gap Kubernetes fills.

---

### What Kubernetes Actually Does

Kubernetes (often abbreviated "K8s") is an **open-source container orchestration platform** originally developed by Google, based on their internal system called Borg which had been running billions of containers per week for over a decade.

It gives you:

| Capability | What it means in plain English |
|------------|-------------------------------|
| **Scheduling** | Decides which server should run each container |
| **Self-healing** | Automatically restarts crashed containers; replaces failed nodes |
| **Scaling** | Adds or removes container replicas based on CPU/memory usage |
| **Service discovery** | Containers find each other by name, not IP address |
| **Load balancing** | Spreads traffic across replicas automatically |
| **Rolling updates** | Deploy new versions with zero downtime |
| **Rollback** | One command to go back to the previous version |
| **Config management** | Separate application config from code |
| **Secret management** | Secure storage for passwords and API keys |
| **Storage orchestration** | Attach persistent storage to containers automatically |

> **[!NOTE]** Kubernetes is a **declarative** system. You describe *what you want* (3 replicas of user-service), and Kubernetes continuously works to make reality match your description — automatically, forever.

---

## Chapter 2: Key Concepts Before We Begin

### Declarative vs Imperative

**Imperative** (telling it *how*):
```
"Start container A on node 1. Start container B on node 2. If A fails, restart it on node 3."
```

**Declarative** (telling it *what*):
```
"I want 3 replicas of user-service running at all times."
```

Kubernetes is **declarative**. You write YAML files describing your desired state, apply them to the cluster, and Kubernetes figures out how to achieve and maintain that state. This is why the same YAML works on your laptop and in production — you describe *what*, not *how*.

### The Reconciliation Loop

The core of how Kubernetes works is a **control loop**:

```
┌──────────────┐     observe      ┌──────────────┐
│   Desired    │ ◄──────────────► │   Actual     │
│   State      │                  │   State      │
│  (your YAML) │     reconcile    │  (cluster)   │
└──────────────┘ ────────────────► └──────────────┘
                  "make it match"
```

Think of a **thermostat**: you set 21°C (desired state). The thermostat reads the room temperature (actual state). If it's cold, it turns on the heating. It never stops checking. Kubernetes works the same way — every controller constantly compares desired vs actual state and corrects any drift.

---

# Part 2: Kubernetes Architecture

## Chapter 3: The Big Picture

A Kubernetes cluster consists of two types of machines:

```
┌────────────────────────────────────────────────────────────────┐
│                        KUBERNETES CLUSTER                      │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    CONTROL PLANE                        │  │
│  │  ┌─────────────┐  ┌──────┐  ┌──────────────────────┐   │  │
│  │  │ kube-apiserver│ │ etcd │  │kube-controller-manager│  │  │
│  │  │  "front desk"│ │ "DB" │  │    "autopilot"       │   │  │
│  │  └─────────────┘  └──────┘  └──────────────────────┘   │  │
│  │              ┌──────────────────┐                        │  │
│  │              │  kube-scheduler  │                        │  │
│  │              │   "placement"    │                        │  │
│  │              └──────────────────┘                        │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │  Worker Node │  │  Worker Node │  │  Worker Node │        │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │        │
│  │  │kubelet │  │  │  │kubelet │  │  │  │kubelet │  │        │
│  │  │kube-   │  │  │  │kube-   │  │  │  │kube-   │  │        │
│  │  │proxy   │  │  │  │proxy   │  │  │  │proxy   │  │        │
│  │  │[pods]  │  │  │  │[pods]  │  │  │  │[pods]  │  │        │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└────────────────────────────────────────────────────────────────┘
```

---

## Chapter 4: The Control Plane

The control plane is the brain of the cluster. It makes decisions and maintains the desired state.

### kube-apiserver — The Front Desk
Every interaction with Kubernetes goes through the API server. `kubectl apply`, CI/CD pipelines, the dashboard, other components — they all talk to the API server via REST/HTTP.

```
kubectl apply -f deployment.yaml
      │
      ▼
 kube-apiserver ──► validates YAML ──► stores in etcd ──► notifies controllers
```

It is stateless and can be run in multiple replicas for high availability.

### etcd — The Database of Truth
etcd is a distributed key-value store that holds the **entire cluster state** — every object you've ever created (deployments, services, pods, secrets). It is the single source of truth.

> **[!WARNING]** If etcd loses data, your cluster loses all configuration. Always back up etcd in production. Most managed Kubernetes services (EKS, GKE, AKS) do this automatically.

### kube-scheduler — The Placement Engine
When a new Pod needs to run, the scheduler decides *which worker node* should run it. It considers:
- Available CPU and memory on each node
- Node affinity rules (e.g., "run on nodes in us-east-1a")
- Pod anti-affinity (e.g., "don't run two replicas on the same node")
- Taints and tolerations (e.g., "only run on GPU nodes")

### kube-controller-manager — The Autopilot
This runs a collection of controllers, each watching for a specific type of object and reconciling actual state to desired state:

| Controller | What it does |
|------------|-------------|
| Deployment Controller | Ensures the correct number of ReplicaSet replicas exist |
| ReplicaSet Controller | Ensures the correct number of Pods are running |
| Node Controller | Marks nodes as unavailable when they stop responding |
| Job Controller | Runs batch jobs to completion |
| Service Account Controller | Creates default service accounts in new namespaces |

---

## Chapter 5: Worker Nodes

Worker nodes are the machines that actually run your application containers.

### kubelet — The Node Agent
The kubelet runs on every worker node. It:
- Registers the node with the API server
- Watches for Pod assignments (via the API server)
- Starts/stops containers via the container runtime
- Reports pod and node status back to the API server
- Runs liveness and readiness probes

### kube-proxy — The Network Plumber
kube-proxy runs on every node and implements Kubernetes Services by managing iptables (or IPVS) rules. When you send traffic to a Service's virtual IP address, kube-proxy routes it to one of the real Pod IPs behind the service.

### Container Runtime
The actual software that starts and stops containers. Kubernetes uses the **Container Runtime Interface (CRI)** to talk to:
- **containerd** (most common — used by Docker Desktop, EKS, GKE)
- **CRI-O** (used by OpenShift)

---

# Part 3: Core Workload Objects

## Chapter 6: Pods — The Basic Building Block

A **Pod** is the smallest deployable unit in Kubernetes. It wraps one or more containers that:
- Share the same network namespace (same IP, same `localhost`)
- Share the same storage volumes
- Are always scheduled together on the same node

### Why Not Just Containers?

Pods exist because some applications need **tightly-coupled containers**. For example:
- A web server + a log shipper (sidecar pattern)
- An application + a configuration-reloader (ambassador pattern)
- A data transformer that pre-processes data before the main app (init container)

### Pod Lifecycle

```
Pending ──► Running ──► Succeeded (for jobs)
              │
              ▼
           Failed ──► (CrashLoopBackOff if keeps restarting)
```

### A Pod YAML Explained

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: user-service-pod        # Name of the pod
  namespace: microservices      # Which namespace it lives in
  labels:
    app: user-service           # Labels used by Services to find this pod
spec:
  containers:
    - name: user-service        # Container name (within the pod)
      image: user-service:1.0  # Docker image to run
      ports:
        - containerPort: 8081   # Port the app listens on (informational only)
      env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"         # Environment variable
      resources:
        requests:
          cpu: 100m             # Minimum CPU (100 millicores = 0.1 cores)
          memory: 128Mi         # Minimum memory
        limits:
          cpu: 500m             # Maximum CPU
          memory: 256Mi         # Maximum memory (OOMKilled if exceeded)
```

> **[!TIP]** You almost never create Pods directly. You create **Deployments** which manage Pods for you. If you create a Pod directly and it crashes, it stays dead. A Deployment automatically restarts it.

---

## Chapter 7: Deployments — Managing Replicas

A **Deployment** manages a set of identical Pod replicas and handles rolling updates and rollbacks.

### Deployment → ReplicaSet → Pods

```
Deployment (desired: 3 replicas, image: v2)
    │
    ├── ReplicaSet (v2) ──► Pod-1 (v2)
    │                  ──► Pod-2 (v2)
    │                  ──► Pod-3 (v2)
    │
    └── ReplicaSet (v1) [scaled to 0 after update]
```

When you update a Deployment (e.g., new image), Kubernetes creates a **new ReplicaSet** and gradually shifts traffic from the old one to the new one. The old ReplicaSet is kept (scaled to 0) so you can roll back instantly.

### Rolling Update Strategy

```
Before update: [v1] [v1] [v1]

Step 1: Start one v2 pod
        [v1] [v1] [v1] [v2]   ← maxSurge=1 allows extra pod

Step 2: Remove one v1 pod (after v2 is ready)
        [v1] [v1] [v2]

Step 3: Start another v2 pod
        [v1] [v1] [v2] [v2]

Step 4: Remove another v1 pod
        [v1] [v2] [v2]

...and so on until all pods are v2
```

`maxUnavailable: 0` ensures no requests are dropped during the update.

### Full Deployment YAML (user-service)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: microservices
spec:
  replicas: 3                    # How many pod copies to run
  selector:
    matchLabels:
      app: user-service          # Which pods this Deployment manages
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1                # Allow 1 extra pod during update
      maxUnavailable: 0          # Never go below desired replica count
  template:                      # Pod template — all pods look like this
    metadata:
      labels:
        app: user-service
    spec:
      containers:
        - name: user-service
          image: ghcr.io/pawanITC/user-service:v1.2.3
          # --- Health checks ---
          livenessProbe:          # Restart container if this fails
            httpGet:
              path: /actuator/health/liveness
              port: 8081
            initialDelaySeconds: 60   # Wait 60s before first check (JVM startup)
            periodSeconds: 10         # Check every 10s
            failureThreshold: 3       # Restart after 3 consecutive failures
          readinessProbe:         # Remove from load balancer if this fails
            httpGet:
              path: /actuator/health/readiness
              port: 8081
            initialDelaySeconds: 30
            periodSeconds: 10
          startupProbe:           # Only for initial startup — overrides liveness
            httpGet:
              path: /actuator/health/liveness
              port: 8081
            failureThreshold: 30  # 30 × 10s = 5 minutes for startup
            periodSeconds: 10
```

### Rolling Back

```bash
# View rollout history
kubectl rollout history deployment/user-service -n microservices

# Roll back to previous version
kubectl rollout undo deployment/user-service -n microservices

# Roll back to specific revision
kubectl rollout undo deployment/user-service --to-revision=3 -n microservices
```

---

## Chapter 8: Services — Stable Network Endpoints

**The Problem:** Pod IP addresses are ephemeral. Every time a Pod is created (after a crash, update, or scaling event), it gets a new IP address. If order-service hard-codes user-service's IP, the connection breaks every time user-service restarts.

**The Solution:** A **Service** provides a stable virtual IP address (ClusterIP) and DNS name that never changes, regardless of how many times the underlying Pods restart.

```
order-service ──► user-service (Service)
                        │
                        │ kube-proxy load balances to:
                        ├──► Pod-1 (10.244.1.5)
                        ├──► Pod-2 (10.244.2.8)
                        └──► Pod-3 (10.244.3.2)
```

### Service Types

| Type | Accessible From | Use Case |
|------|----------------|----------|
| **ClusterIP** | Inside cluster only | Internal service-to-service communication |
| **NodePort** | Outside cluster via `<NodeIP>:<NodePort>` | Development, simple external access |
| **LoadBalancer** | Outside cluster via cloud load balancer | Production external traffic |
| **ExternalName** | Inside cluster via DNS | Alias for external services (e.g., a managed DB) |

### DNS-Based Service Discovery

Kubernetes has built-in DNS (CoreDNS). Every Service gets a DNS name:

```
<service-name>.<namespace>.svc.cluster.local
```

So `user-service` in the `microservices` namespace is reachable at:
```
user-service.microservices.svc.cluster.local
```

Within the same namespace, you can just use `user-service`.

This is exactly how `order-service` calls `user-service` in our template — via the `USER_SERVICE_URL` environment variable set to `http://user-service.microservices.svc.cluster.local`.

### Service YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: microservices
spec:
  type: ClusterIP              # Only reachable inside the cluster
  selector:
    app: user-service          # Routes to pods with this label
  ports:
    - name: http
      port: 80                 # Port the Service listens on
      targetPort: 8081         # Port on the Pod to forward to
      protocol: TCP
```

---

## Chapter 9: ConfigMaps and Secrets

### Why Separate Config from Code?

Hardcoding configuration (database URLs, feature flags, log levels) in your application means building a new Docker image every time config changes. The **12-Factor App** methodology says configuration should come from the environment.

### ConfigMaps — Non-Sensitive Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: microservices
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8081"
  LOGGING_LEVEL_COM_EXAMPLE: "INFO"
```

Injected into Pods as environment variables:
```yaml
envFrom:
  - configMapRef:
      name: user-service-config
```

Or mounted as files:
```yaml
volumes:
  - name: config
    configMap:
      name: user-service-config
volumeMounts:
  - name: config
    mountPath: /app/config
```

### Secrets — Sensitive Data

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: user-service-secret
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=   # base64 encoded (NOT encrypted!)
```

> **[!WARNING]** Base64 is **encoding**, not **encryption**. Anyone with access to the Secret object can decode it instantly. Kubernetes Secrets provide access control (via RBAC), not cryptographic protection. For true secret management, use one of these:
> - **External Secrets Operator** — syncs from AWS Secrets Manager, GCP Secret Manager, or HashiCorp Vault
> - **Sealed Secrets** — asymmetrically encrypts secrets so they can be safely stored in git
> - **HashiCorp Vault** — dedicated secrets management platform

To create secrets without putting values in YAML files:
```bash
kubectl create secret generic user-service-secret \
  --from-literal=DB_USERNAME=admin \
  --from-literal=DB_PASSWORD=supersecret \
  -n microservices
```

---

## Chapter 10: Namespaces — Virtual Clusters

**Namespaces** partition a single Kubernetes cluster into virtual clusters. They provide:
- **Name scoping** — two teams can each have a `user-service` deployment in different namespaces
- **Resource quotas** — limit total CPU/memory per namespace
- **Access control** — RBAC can be scoped to a namespace

### Default Namespaces

| Namespace | Purpose |
|-----------|---------|
| `default` | Where objects go if you don't specify a namespace |
| `kube-system` | Kubernetes internal components (CoreDNS, kube-proxy) |
| `kube-public` | Publicly readable data (cluster info) |
| `kube-node-lease` | Node heartbeat leases |

### Our Template Uses `microservices`

We keep all application resources in the `microservices` namespace, isolated from system components. This makes it easy to:
- Grant developers access to just `microservices`, not the whole cluster
- Apply resource quotas to application workloads only
- Tear down everything with `kubectl delete namespace microservices`

---

# Part 4: Configuration and Storage

## Chapter 11: Persistent Storage

Containers have **ephemeral storage** — files written inside a container are lost when it restarts. For databases and stateful apps, you need persistent storage.

### The Storage Stack

```
┌─────────────────────────────────┐
│     PersistentVolumeClaim (PVC) │  ← App requests storage ("I need 10Gi")
│         "storage request"       │
└───────────────┬─────────────────┘
                │ bound to
┌───────────────▼─────────────────┐
│      PersistentVolume (PV)      │  ← Actual storage provision
│      "storage provision"        │
└───────────────┬─────────────────┘
                │ backed by
┌───────────────▼─────────────────┐
│         StorageClass            │  ← Defines the type (SSD, HDD, NFS)
│    "storage type definition"    │  ← Dynamic provisioning via cloud provider
└─────────────────────────────────┘
```

### Volume Types in our Template

Our microservices use two ephemeral volume types (no persistence needed — we use an external database):

```yaml
volumes:
  - name: tmp
    emptyDir: {}    # Temporary files — lost when pod restarts (required for readOnlyRootFilesystem)
  - name: logs
    emptyDir: {}    # Log files — also ephemeral
```

> **[!TIP]** Our microservices connect to external PostgreSQL databases rather than running a database inside Kubernetes. This is the recommended approach for production — databases need careful storage management, backup strategies, and are better operated as managed services (AWS RDS, Cloud SQL, Azure Database).

---

# Part 5: Networking Deep Dive

## Chapter 12: Kubernetes Networking Fundamentals

### The Four Networking Problems

Kubernetes networking solves four distinct communication types:

```
1. Container ↔ Container (within a Pod)
   └─ Same network namespace, communicate via localhost

2. Pod ↔ Pod (across nodes)
   └─ All pods get a unique IP; can communicate directly
   └─ Implemented by CNI plugins (Calico, Flannel, Cilium)

3. Pod ↔ Service
   └─ Service provides stable virtual IP
   └─ kube-proxy handles the routing

4. External ↔ Service
   └─ NodePort, LoadBalancer, or Ingress
```

### The Kubernetes Networking Model

Every Pod gets its own IP address. Pods can communicate with any other Pod on any node **without NAT** (Network Address Translation). This flat network model simplifies service discovery.

The implementation of this flat network is done by **CNI (Container Network Interface) plugins**:

| CNI Plugin | Characteristics | Best For |
|-----------|----------------|---------|
| **Flannel** | Simple, overlay network | Small clusters, learning |
| **Calico** | BGP routing + NetworkPolicies | Production, performance |
| **Cilium** | eBPF-based, advanced observability | High performance, security |

---

## Chapter 13: Ingress — The Front Door

A **Service** of type LoadBalancer gives you one IP per service. In production, you might have 50 services — you can't have 50 load balancers. That's expensive and unmanageable.

An **Ingress** is a Layer 7 (HTTP/HTTPS) router that sits in front of all services and routes traffic based on URL paths and hostnames.

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│         Ingress (nginx)                 │
│                                         │
│  /api/v1/users  ──────────────────────► │──► user-service:80
│  /api/v1/orders ──────────────────────► │──► order-service:80
│  /admin         ──────────────────────► │──► admin-service:80
└─────────────────────────────────────────┘
```

### Ingress Controller vs Ingress Resource

- **Ingress Controller**: The actual software (NGINX, Traefik, Kong) that runs in your cluster and reads routing rules
- **Ingress Resource**: The YAML file that defines the routing rules

You need **both**. The Ingress resource alone does nothing without a controller to implement it.

### Our Template's Ingress (local)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: microservices.local
      http:
        paths:
          - path: /api/v1/users(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: user-service
                port:
                  number: 80
          - path: /api/v1/orders(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: order-service
                port:
                  number: 80
```

### TLS with cert-manager

In production, you want HTTPS. **cert-manager** automates certificate management:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts: [api.example.com]
      secretName: api-example-com-tls
```

cert-manager watches for Ingress resources with this annotation, requests a certificate from Let's Encrypt, and stores it in the named Secret automatically. Renewals happen automatically.

---

## Chapter 14: NetworkPolicies — Micro-Segmentation

By default, **every pod in a Kubernetes cluster can communicate with every other pod**. In a multi-tenant cluster or any security-sensitive environment, this is unacceptable.

**NetworkPolicies** are firewall rules for pods. They use label selectors to define which pods can send/receive traffic.

### The Zero-Trust Pattern

Our template uses the zero-trust pattern:

**Step 1: Block everything**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: microservices
spec:
  podSelector: {}    # Applies to ALL pods
  policyTypes:
    - Ingress
    - Egress
```

**Step 2: Explicitly allow what's needed**
```yaml
# Allow user-service to receive traffic from ingress-nginx and order-service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-user-service-ingress
spec:
  podSelector:
    matchLabels:
      app: user-service
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
    - from:
        - podSelector:
            matchLabels:
              app: order-service
```

### Traffic Map in Our Template

```
Internet
    │
    ▼
ingress-nginx ──────────────────────────────► user-service (8081) ✅
ingress-nginx ──────────────────────────────► order-service (8082) ✅
order-service ──────────────────────────────► user-service (8081) ✅
order-service ─────────────────────────────X► any other service  ❌
user-service  ─────────────────────────────X► order-service      ❌
any pod       ──────────────────────────────► kube-dns (53/UDP)  ✅
any pod       ──────────────────────────────► PostgreSQL (5432)  ✅
any pod       ─────────────────────────────X► internet           ❌
```

---

## Chapter 15: Service Mesh (Overview)

For advanced use cases, a **service mesh** like Istio or Linkerd adds a sidecar proxy (Envoy) to every pod. This enables:

| Feature | Description |
|---------|-------------|
| **mTLS** | Mutual TLS between all services — encrypted and authenticated |
| **Circuit breaking** | Stop calling a failing service, return fast error |
| **Retries** | Automatically retry failed requests |
| **Rate limiting** | Limit requests per second per service |
| **Distributed tracing** | See the full request path across services |
| **Traffic splitting** | Send 5% of traffic to new version (canary) |

> **[!NOTE]** Service meshes add complexity and overhead (the sidecar container uses CPU/memory). Only add a service mesh when you actually need these features. Start without one and add it later if required.

---

# Part 6: Security

## Chapter 16: The 4Cs of Cloud Native Security

Security in Kubernetes is layered:

```
┌──────────────────────────────────────────────┐
│                    Code                      │  ← Your application code
│  ┌────────────────────────────────────────┐  │
│  │              Container                 │  │  ← Docker image, base OS
│  │  ┌──────────────────────────────────┐  │  │
│  │  │            Cluster               │  │  │  ← K8s RBAC, NetworkPolicies
│  │  │  ┌────────────────────────────┐  │  │  │
│  │  │  │           Cloud            │  │  │  │  ← IAM, VPC, firewall rules
│  │  │  └────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

Kubernetes is responsible for the **Cluster** layer. You are responsible for Code and Container. Your cloud provider handles Cloud.

---

## Chapter 17: RBAC — Role-Based Access Control

**RBAC** controls who can do what to which Kubernetes resources.

### Core Concepts

```
WHO        WHAT          WHICH RESOURCES
Subject ── Verbs ─────── Resources
  │                          │
  │  (get/list/watch/        │
  │   create/update/         │
  │   patch/delete)          │
  │                          │
  ├── User                   ├── pods
  ├── Group                  ├── services
  └── ServiceAccount         ├── deployments
                             ├── secrets
                             └── configmaps
```

### Roles vs ClusterRoles

- **Role**: Grants permissions within a **single namespace**
- **ClusterRole**: Grants permissions **cluster-wide** (or reusable across namespaces)

### Our Template's RBAC

Each microservice has its own **ServiceAccount** and a **Role** granting only what it needs:

```yaml
# user-service only needs to read its own configmap and secret
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: user-service-role
  namespace: microservices
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    resourceNames: ["user-service-config", "user-service-secret"]
    verbs: ["get", "list", "watch"]
```

> **[!TIP]** Always use the **principle of least privilege** — grant the minimum permissions necessary. If user-service doesn't need to create pods or read other services' secrets, don't grant those permissions.

---

## Chapter 18: Pod Security

### SecurityContext

Every container in our template runs with a hardened security context:

```yaml
securityContext:
  runAsNonRoot: true          # Container must not run as root (uid 0)
  runAsUser: 1001             # Run as uid 1001 (the "spring" user we create in Dockerfile)
  allowPrivilegeEscalation: false  # Cannot gain more privileges than parent
  readOnlyRootFilesystem: true     # Cannot write to container filesystem
  capabilities:
    drop: ["ALL"]             # Drop all Linux capabilities
seccompProfile:
  type: RuntimeDefault        # Apply default syscall filter
```

**Why does this matter?**

If an attacker exploits a vulnerability in your application and gains code execution inside the container:
- `runAsNonRoot` — they can't act as root inside the container
- `readOnlyRootFilesystem` — they can't write malware to disk
- `capabilities: drop ALL` — they can't open raw sockets, mount filesystems, etc.
- `seccompProfile` — restricts which Linux system calls can be made

These controls contain the blast radius of a security incident.

### automountServiceAccountToken: false

By default, Kubernetes mounts a service account token into every pod. This token can be used to call the Kubernetes API. Most applications don't need this, so we disable it:

```yaml
spec:
  automountServiceAccountToken: false
```

---

## Chapter 19: Secrets Management at Scale

### The Problem with Kubernetes Secrets

Kubernetes Secrets are only base64-encoded, not encrypted, by default. To secure them properly:

1. **Enable etcd encryption at rest** — most managed K8s services do this
2. **Use RBAC** — restrict who can read secrets
3. **Don't store secrets in git** — even as Kubernetes Secret YAML files

### Production Approach: External Secrets Operator

The **External Secrets Operator** syncs secrets from a trusted external store into Kubernetes:

```
AWS Secrets Manager ─────────────────────────► Kubernetes Secret
GCP Secret Manager  ──► External Secrets    ►  (created and kept
HashiCorp Vault     ──► Operator            ►   in sync)
Azure Key Vault     ─────────────────────────►
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: user-service-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: user-service-secret
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: microservices/user-service
        property: db_password
```

### Alternative: Sealed Secrets

**Sealed Secrets** lets you encrypt secrets so they can be safely committed to git:

```bash
# Install kubeseal CLI
# Encrypt a secret
kubectl create secret generic my-secret --dry-run=client \
  --from-literal=password=supersecret -o yaml | \
  kubeseal --cert pub-cert.pem -o yaml > my-sealedsecret.yaml

# The SealedSecret can now be committed to git safely
# Only the cluster can decrypt it (using the private key)
git add my-sealedsecret.yaml  # ✅ Safe to commit
```

---

# Part 7: Scaling

## Chapter 20: Horizontal Pod Autoscaler (HPA)

The HPA automatically scales the number of Pod replicas based on observed metrics.

```
         CPU < 70%        CPU > 70%
              │                │
              ▼                ▼
         Scale down        Scale up
         (slowly)          (quickly)

3 replicas ──────────────────────────► 8 replicas
           ◄──────────────────────────
```

### HPA YAML

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70    # Scale up when average CPU > 70%
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down (prevents flapping)
    scaleUp:
      stabilizationWindowSeconds: 30   # React to spikes within 30s
```

> **[!NOTE]** HPA requires metrics-server to be installed in the cluster. Most managed K8s services include it. Docker Desktop includes it too.

### Scaling Interaction with PodDisruptionBudgets

A **PodDisruptionBudget (PDB)** prevents the cluster from taking down too many pods at once during voluntary operations (node drains, cluster upgrades):

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: user-service-pdb
spec:
  minAvailable: 2           # At least 2 pods must always be running
  selector:
    matchLabels:
      app: user-service
```

With HPA (min 3) + PDB (minAvailable 2):
- Cluster can safely drain one node at a time
- HPA can scale down one pod at a time
- You never lose more than 1 replica during maintenance

---

## Chapter 21: Resource Requests and Limits

Understanding resource configuration is critical for cluster stability.

### CPU

CPU is measured in **millicores** (m):
- `100m` = 0.1 CPU cores = 10% of one core
- `500m` = 0.5 CPU cores
- `1000m` = 1 = one full CPU core

**CPU is throttled** (not killed) when a container exceeds its limit. The container slows down but keeps running.

### Memory

Memory is measured in bytes:
- `128Mi` = 128 mebibytes
- `256Mi` = 256 mebibytes
- `1Gi` = 1 gibibyte

**Memory is hard-limited.** If a container exceeds its memory limit, the kernel kills it with **OOMKilled** (Out of Memory Killed). The pod will restart.

### Quality of Service Classes

Based on requests/limits, Kubernetes assigns a QoS class:

| Class | Condition | Eviction Priority |
|-------|-----------|------------------|
| **Guaranteed** | requests == limits for all containers | Last to be evicted |
| **Burstable** | requests < limits | Middle priority |
| **BestEffort** | No requests or limits set | First to be evicted |

> **[!TIP]** For production workloads, set both requests and limits. For critical services, consider making them Guaranteed (requests == limits) so they're never evicted under pressure.

### Our Template's Resource Configuration

```yaml
# user-service — a lightweight Spring Boot app
resources:
  requests:
    cpu: 100m      # Reserve 0.1 cores for scheduling
    memory: 128Mi  # Reserve 128MB
  limits:
    cpu: 500m      # Never use more than 0.5 cores
    memory: 256Mi  # OOMKilled if exceeded
```

These are conservative values. Monitor real usage with `kubectl top pods` and adjust.

---

## Chapter 22: Cluster Autoscaler

The Cluster Autoscaler (CA) adds or removes **worker nodes** when:
- Pods are stuck in `Pending` state because no node has enough resources → add node
- Nodes are underutilised and their pods fit on other nodes → remove node

```
HPA scales pods ──────────────────────────────────────────────────► more pods needed
                                                                          │
                                                                          ▼
                                                              No node has enough capacity
                                                                          │
                                                                          ▼
Cluster Autoscaler adds a new node ◄──────────────────────────────────────
```

Cluster Autoscaler is available for all major cloud providers (AWS, GCP, Azure) and is configured through your cloud provider, not in Kubernetes YAML.

---

# Part 8: GitOps with ArgoCD

## Chapter 23: What is GitOps?

**GitOps** is a deployment model where:
1. **Git is the single source of truth** for both application code and infrastructure
2. Changes to the cluster are **always made via git** (pull request → merge → automatic deploy)
3. An automated agent **continuously reconciles** the cluster to match what's in git

```
Developer
    │
    │  git push / merge PR
    ▼
Git Repository (source of truth)
    │
    │  ArgoCD watches for changes
    ▼
ArgoCD detects drift
    │
    │  automatically syncs
    ▼
Kubernetes Cluster
```

### Benefits of GitOps

| Benefit | Description |
|---------|-------------|
| **Auditability** | Every cluster change is a git commit with author, timestamp, and message |
| **Rollback** | `git revert` rolls back any change instantly |
| **Consistency** | Cluster always matches git — no manual changes drift |
| **Pull-based** | The cluster pulls from git; you don't push secrets into the cluster from CI |
| **Disaster recovery** | Rebuild any cluster by pointing ArgoCD at your git repo |

---

## Chapter 24: ArgoCD Architecture

ArgoCD is the most popular GitOps tool for Kubernetes. It runs inside your cluster and continuously syncs applications from git.

```
┌─────────────────────────────────────────┐
│              ArgoCD                     │
│                                         │
│  ┌─────────────┐    ┌────────────────┐  │
│  │ API Server  │    │  Repo Server   │  │
│  │ (UI + CLI)  │    │ (clones repos, │  │
│  └─────────────┘    │  renders YAML) │  │
│                     └────────────────┘  │
│  ┌──────────────────────────────────┐   │
│  │    Application Controller        │   │
│  │  (watches cluster + git,         │   │
│  │   detects drift, syncs)          │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Core Concepts

**Application**: An ArgoCD resource that links a git repo path to a Kubernetes namespace.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
  namespace: argocd
spec:
  project: microservices
  source:
    repoURL: https://github.com/PawanITC/Kubernetes.git
    targetRevision: HEAD
    path: k8s/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices
  syncPolicy:
    automated:
      prune: true       # Delete resources removed from git
      selfHeal: true    # Revert manual cluster changes
```

### App-of-Apps Pattern

Instead of registering each application manually in ArgoCD, use the **app-of-apps** pattern: one parent Application that manages all child Applications.

```
app-of-apps (ArgoCD Application)
    │
    │  watches argocd/apps/ directory in git
    │
    ├── user-service-app.yaml ──► creates user-service Application
    └── order-service-app.yaml ──► creates order-service Application
```

This means adding a new microservice is as simple as adding a new YAML file to `argocd/apps/` in git. ArgoCD picks it up and deploys it automatically.

---

## Chapter 25: Setting Up ArgoCD

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Wait for ArgoCD to start
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=5m

# 3. Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# 4. Access the UI (port-forward)
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080

# 5. Deploy our app-of-apps
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/app-of-apps.yaml
```

After step 5, ArgoCD will automatically discover and deploy `user-service` and `order-service` from the `argocd/apps/` directory.

### Sync Waves

When you have dependencies (e.g., create namespace before deploying services), use sync waves:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"    # Deploy first
```

Objects with lower wave numbers are synced before higher ones.

---

# Part 9: Observability

## Chapter 26: The Three Pillars

**Observability** = understanding what your system is doing from the outside, without modifying it.

```
┌──────────┐  ┌──────────┐  ┌──────────────┐
│  Metrics │  │   Logs   │  │   Traces     │
│          │  │          │  │              │
│ Numbers  │  │  Text    │  │ Request path │
│ over     │  │  events  │  │ across       │
│ time     │  │          │  │ services     │
│          │  │          │  │              │
│Prometheus│  │  Loki /  │  │  Jaeger /    │
│+ Grafana │  │  EFK     │  │  Zipkin      │
└──────────┘  └──────────┘  └──────────────┘
```

## Chapter 27: Metrics with Prometheus

**Prometheus** scrapes metrics from your services via HTTP. Spring Boot Actuator exposes metrics at `/actuator/prometheus`.

### Key Metrics to Monitor (RED Method)

| Metric | Description | PromQL Example |
|--------|-------------|----------------|
| **Rate** | Requests per second | `rate(http_server_requests_seconds_count[1m])` |
| **Errors** | Error rate | `rate(http_server_requests_seconds_count{status=~"5.."}[1m])` |
| **Duration** | Request latency p99 | `histogram_quantile(0.99, rate(http_server_requests_seconds_bucket[1m]))` |

### ServiceMonitor (Prometheus Operator)

The Prometheus Operator watches for `ServiceMonitor` resources and automatically configures Prometheus to scrape them:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: user-service
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 30s
```

### Install Prometheus Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

This installs Prometheus, Grafana, AlertManager, and pre-built dashboards for Kubernetes itself.

---

# Part 10: Hands-On Walkthrough

## Chapter 28: Local Setup Step-by-Step

### Prerequisites

1. Install **Docker Desktop**: https://www.docker.com/products/docker-desktop/
2. Enable Kubernetes: `Settings → Kubernetes → Enable Kubernetes → Apply & Restart`
3. Install tools:
   ```bash
   # kubectl (usually included with Docker Desktop)
   kubectl version --client

   # helm
   # Windows: winget install Helm.Helm
   # Mac: brew install helm

   # kustomize
   # Windows: winget install Kubernetes.kustomize
   # Mac: brew install kustomize
   ```

### Step 1: Verify Kubernetes is Running

```bash
kubectl cluster-info
# Output: Kubernetes control plane is running at https://127.0.0.1:6443

kubectl get nodes
# Output: NAME             STATUS   ROLES           AGE
#         docker-desktop   Ready    control-plane   5d
```

### Step 2: Run the Setup Script

```bash
cd Kubernetes
chmod +x scripts/*.sh
./scripts/setup-local.sh
```

Or manually:

### Step 3: Build Docker Images

```bash
# Build both services
docker build -t user-service:latest services/user-service/
docker build -t order-service:latest services/order-service/
```

### Step 4: Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

Wait for it to be ready:
```bash
kubectl wait --for=condition=available deployment/ingress-nginx-controller \
  -n ingress-nginx --timeout=3m
```

### Step 5: Deploy the Services

```bash
kubectl apply -k k8s/overlays/local
```

This creates:
- The `microservices` namespace
- ServiceAccounts for each service
- ConfigMaps for configuration
- Placeholder Secrets (using H2 DB locally)
- Deployments for both services
- Services for networking
- Ingress for external access

### Step 6: Wait for Deployments

```bash
kubectl rollout status deployment/user-service  -n microservices
kubectl rollout status deployment/order-service -n microservices
```

### Step 7: Add Hosts Entry

```bash
# Linux/Mac
sudo sh -c 'echo "127.0.0.1 microservices.local" >> /etc/hosts'

# Windows (run PowerShell as Administrator)
# Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 microservices.local"
```

### Step 8: Test the APIs

```bash
# Create a user
curl -s -X POST http://microservices.local/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Jane","lastName":"Doe","email":"jane@example.com"}' | jq .

# List users
curl -s http://microservices.local/api/v1/users | jq .

# Create an order (uses userId from the user created above)
curl -s -X POST http://microservices.local/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productName":"Mechanical Keyboard","quantity":1,"price":149.99,"shippingAddress":"456 Dev St"}' | jq .

# List orders
curl -s http://microservices.local/api/v1/orders | jq .
```

### Step 9: Explore Kubernetes Resources

```bash
# See what's running
kubectl get all -n microservices

# View pod logs
kubectl logs -f deploy/user-service -n microservices

# Get pod details
kubectl describe pod -l app=user-service -n microservices

# Watch pods in real-time
kubectl get pods -n microservices -w
```

### Step 10: Test Self-Healing

```bash
# Delete a pod manually
kubectl delete pod -l app=user-service -n microservices

# Watch Kubernetes automatically recreate it
kubectl get pods -n microservices -w
# You'll see a new pod appear within seconds
```

### Step 11: Test Scaling

```bash
# Scale user-service to 3 replicas
kubectl scale deployment/user-service --replicas=3 -n microservices

# Watch the new pods start
kubectl get pods -n microservices -w

# The service automatically load-balances across all 3 replicas
```

---

## Chapter 29: Production Deployment Checklist

Before deploying to production, verify each item:

### Infrastructure
- [ ] Kubernetes cluster provisioned (EKS / GKE / AKS / bare metal)
- [ ] NGINX Ingress Controller installed
- [ ] cert-manager installed
- [ ] PostgreSQL databases provisioned and accessible from cluster
- [ ] Container registry configured (GHCR / ECR / GCR / ACR)

### Application
- [ ] Docker images built and pushed to registry
- [ ] Image tags use specific SHA (not `latest`) for reproducibility
- [ ] Health check endpoints tested: `/actuator/health/liveness` and `/actuator/health/readiness`
- [ ] Resource requests and limits set (not too tight, not too loose)

### Security
- [ ] Secrets created in cluster (NOT in git)
- [ ] RBAC configured — ServiceAccounts with least-privilege Roles
- [ ] NetworkPolicies applied (start with default-deny)
- [ ] Pod SecurityContext: runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities
- [ ] Container images scanned for vulnerabilities (Trivy, Snyk, Grype)
- [ ] No sensitive data in ConfigMaps or environment variables

### Availability
- [ ] `replicas: 3` minimum for production workloads
- [ ] HPA configured with sensible min/max and CPU target
- [ ] PodDisruptionBudget set (minAvailable: 2)
- [ ] Pod anti-affinity: spread across nodes
- [ ] TopologySpreadConstraints: spread across availability zones
- [ ] `terminationGracePeriodSeconds: 60` + preStop hook for graceful shutdown

### Networking
- [ ] Ingress configured with correct hostnames
- [ ] TLS certificates (Let's Encrypt via cert-manager)
- [ ] HTTPS redirect enforced
- [ ] Rate limiting configured on Ingress

### Observability
- [ ] Prometheus scraping metrics from services
- [ ] Grafana dashboards created
- [ ] Alerting rules configured for error rate, latency, pod restarts
- [ ] Centralized logging configured

### GitOps (if using ArgoCD)
- [ ] ArgoCD installed
- [ ] AppProject created with scoped permissions
- [ ] Applications deployed via app-of-apps
- [ ] Auto-sync enabled with self-heal

---

# Part 11: Troubleshooting

## Chapter 30: Diagnosing Common Problems

### CrashLoopBackOff

The container starts, crashes, Kubernetes restarts it, it crashes again.

```bash
# Check what happened before the crash
kubectl logs <pod-name> -n microservices --previous

# See exit code and reason
kubectl describe pod <pod-name> -n microservices
# Look for: "Last State: Terminated  Reason: Error  Exit Code: 1"
```

**Common causes:**
- Application startup error (missing env var, DB connection refused)
- Liveness probe too aggressive (app not started when probe runs)
- OOMKilled (increase memory limit)
- Permission error (app tries to write to read-only filesystem)

### ImagePullBackOff

Kubernetes can't pull the container image.

```bash
kubectl describe pod <pod-name> -n microservices
# Look for: "Failed to pull image: unauthorized"
```

**Common causes:**
- Wrong image name or tag
- Registry requires authentication — create `imagePullSecret`
- Private registry not reachable from cluster

### Pending Pod

Pod is stuck in `Pending` state — it hasn't been scheduled to a node.

```bash
kubectl describe pod <pod-name> -n microservices
# Look for: "Events: 0/1 nodes are available: insufficient memory"
```

**Common causes:**
- Insufficient CPU/memory on any node (reduce requests or add nodes)
- Node selector or affinity rules can't be satisfied
- Taints on nodes that the pod doesn't tolerate

### Service Not Reachable

```bash
# Test from inside the cluster
kubectl run debug --image=curlimages/curl --restart=Never --rm -it \
  -- curl -v http://user-service.microservices.svc.cluster.local/actuator/health

# Check service endpoints
kubectl get endpoints user-service -n microservices
# If endpoints list is empty, the Service selector doesn't match any pods
```

**Common causes:**
- Service selector labels don't match pod labels
- Pod not in Ready state (check readiness probe)
- NetworkPolicy blocking traffic

### Connection Refused / Timeout Between Services

```bash
# Test if NetworkPolicy is blocking
kubectl run debug --image=curlimages/curl --restart=Never --rm -it \
  -n microservices -- curl -v http://user-service/actuator/health
```

**Common causes:**
- NetworkPolicy default-deny with no allow rule
- Wrong service port (80 vs 8081)
- Application not listening on the expected port

### OOMKilled

```bash
kubectl describe pod <pod-name> -n microservices
# Look for: "OOMKilled" or "Reason: OOMKilled"

# Check memory usage
kubectl top pods -n microservices
```

**Fix**: Increase memory limit in the deployment:
```yaml
resources:
  limits:
    memory: 512Mi   # Increase from 256Mi
```

---

## Chapter 31: Essential kubectl Commands

```bash
# ── Viewing Resources ────────────────────────────────────────────────────────
kubectl get pods -n microservices              # List pods
kubectl get pods -n microservices -o wide      # Show node and IP
kubectl get all -n microservices               # All resources
kubectl get events -n microservices \
  --sort-by='.metadata.creationTimestamp'      # Recent events (great for debugging)

# ── Inspecting Resources ─────────────────────────────────────────────────────
kubectl describe pod <name> -n microservices   # Full pod details + events
kubectl describe deployment user-service \
  -n microservices                             # Deployment details

# ── Logs ─────────────────────────────────────────────────────────────────────
kubectl logs <pod-name> -n microservices        # Current logs
kubectl logs <pod-name> -n microservices -f     # Follow / tail logs
kubectl logs <pod-name> -n microservices \
  --previous                                   # Logs from previous (crashed) container
kubectl logs deploy/user-service \
  -n microservices                             # Logs from deployment (any replica)

# ── Debugging ────────────────────────────────────────────────────────────────
kubectl exec -it <pod-name> -n microservices \
  -- /bin/sh                                   # Shell into running container
kubectl port-forward svc/user-service \
  8081:80 -n microservices                    # Port-forward to local machine
kubectl top pods -n microservices              # CPU and memory usage
kubectl top nodes                              # Node resource usage

# ── Scaling ──────────────────────────────────────────────────────────────────
kubectl scale deployment/user-service \
  --replicas=5 -n microservices               # Manual scale
kubectl rollout status deployment/user-service \
  -n microservices                            # Watch rollout progress
kubectl rollout undo deployment/user-service \
  -n microservices                            # Roll back

# ── Applying Changes ─────────────────────────────────────────────────────────
kubectl apply -f deployment.yaml              # Apply a single file
kubectl apply -k k8s/overlays/local           # Apply Kustomize overlay
kubectl delete -k k8s/overlays/local          # Delete everything in overlay
kubectl diff -f deployment.yaml               # Preview changes before applying
```

---

# Appendix A: kubectl Cheat Sheet

```
RESOURCE SHORTCUTS
─────────────────────────────────────────────────────────────────
pods          → po        services      → svc
deployments   → deploy    namespaces    → ns
replicasets   → rs        configmaps    → cm
statefulsets  → sts       persistentvolumeclaims → pvc
daemonsets    → ds        horizontalpodautoscalers → hpa
ingresses     → ing       networkpolicies → netpol
serviceaccounts → sa      roles         → role

MOST-USED COMMANDS
─────────────────────────────────────────────────────────────────
kubectl get po -A                        # All pods in all namespaces
kubectl get po -n ns -w                  # Watch pods (live)
kubectl get po -n ns -o yaml             # Full YAML of a pod
kubectl describe po <name> -n ns         # Events + details
kubectl logs <name> -n ns -f             # Follow logs
kubectl exec -it <pod> -- /bin/sh        # Shell into pod
kubectl port-forward svc/<name> LP:RP    # LocalPort:RemotePort
kubectl apply -k ./overlay               # Kustomize apply
kubectl diff -k ./overlay                # Kustomize diff
kubectl rollout restart deploy/<name>    # Trigger rolling restart
```

---

# Appendix B: Glossary

| Term | Definition |
|------|-----------|
| **ArgoCD** | GitOps continuous delivery tool for Kubernetes |
| **ClusterIP** | Default Service type — only accessible within the cluster |
| **ConfigMap** | Kubernetes object for storing non-sensitive configuration data |
| **Container Runtime** | Software that runs containers (containerd, CRI-O) |
| **Control Plane** | Brain of the cluster: API server, etcd, scheduler, controller-manager |
| **CrashLoopBackOff** | Pod state meaning the container keeps crashing and restarting |
| **Deployment** | Manages a set of replica Pods with rolling update capability |
| **etcd** | Distributed key-value store holding all cluster state |
| **HPA** | HorizontalPodAutoscaler — scales pod replicas based on metrics |
| **Helm** | Package manager for Kubernetes — installs pre-packaged apps (charts) |
| **Ingress** | HTTP/HTTPS routing rules directing external traffic to services |
| **Ingress Controller** | Software implementing Ingress rules (NGINX, Traefik) |
| **kube-proxy** | Node component managing iptables rules for Service networking |
| **kubelet** | Node agent that manages pods on each worker node |
| **Kustomize** | Template-free Kubernetes config customisation tool |
| **Liveness Probe** | Health check — container is restarted if it fails |
| **Namespace** | Virtual cluster within a cluster — isolates groups of resources |
| **NetworkPolicy** | Firewall rules for pods — controls ingress/egress traffic |
| **Node** | A server (physical or virtual) that runs Pods |
| **PDB** | PodDisruptionBudget — minimum available pods during disruptions |
| **Persistent Volume** | A piece of storage in the cluster provisioned by an admin |
| **Pod** | Smallest deployable unit — one or more containers sharing network/storage |
| **RBAC** | Role-Based Access Control — who can do what to which resources |
| **Readiness Probe** | Health check — pod is removed from load balancer if it fails |
| **ReplicaSet** | Ensures a specified number of Pod replicas are running |
| **Secret** | Kubernetes object for storing sensitive data (passwords, tokens) |
| **Service** | Stable network endpoint (virtual IP + DNS) for a set of pods |
| **ServiceAccount** | Identity for pods when calling the Kubernetes API |
| **ServiceMonitor** | Prometheus Operator CRD telling Prometheus what to scrape |
| **StatefulSet** | Like Deployment but for stateful apps — stable pod names and storage |
| **Taint / Toleration** | Taint repels pods from a node; toleration allows pod to schedule there |
| **VPA** | VerticalPodAutoscaler — adjusts pod resource requests/limits automatically |
| **Volume** | Directory accessible to containers in a pod |
| **Worker Node** | Server that runs your application pods |

---

## Further Learning

### Official Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/) — comprehensive, always up to date
- [Kubernetes Interactive Tutorials](https://kubernetes.io/docs/tutorials/kubernetes-basics/) — browser-based, no setup needed
- [CNCF Landscape](https://landscape.cncf.io/) — overview of the entire cloud native ecosystem

### Certifications
| Cert | Focus | Difficulty |
|------|-------|-----------|
| **CKAD** — Certified Kubernetes Application Developer | Running apps on K8s | Intermediate |
| **CKA** — Certified Kubernetes Administrator | Cluster management | Advanced |
| **CKS** — Certified Kubernetes Security Specialist | K8s security | Expert |

### Recommended Reading
- *Kubernetes: Up and Running* — Brendan Burns, Joe Beda, Kelsey Hightower
- *Production Kubernetes* — Josh Rosso et al.
- *Kubernetes Patterns* — Bilgin Ibryam, Roland Huß

### Hands-On Practice
- [killer.sh](https://killer.sh) — realistic CKA/CKAD exam simulators
- [Play with Kubernetes](https://labs.play-with-k8s.com/) — free browser-based cluster
- [Katacoda](https://katacoda.com) — interactive Kubernetes scenarios

---

*This guide was written to accompany the `Kubernetes` repository. Every concept described here is implemented in the template — read the YAML files alongside this guide for the full picture.*
