#!/bin/bash
# =============================================================================
# setup-local.sh — Deploy microservices to local Docker Desktop Kubernetes
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Prerequisites ─────────────────────────────────────────────────────────────
check_prerequisites() {
  log_info "Checking prerequisites..."
  local missing=0
  for cmd in docker kubectl helm; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "  '$cmd' not found. Please install it first."
      missing=1
    else
      log_success "  $cmd: $(${cmd} version --client --short 2>/dev/null || ${cmd} version --short 2>/dev/null | head -1)"
    fi
  done
  [[ $missing -eq 1 ]] && exit 1
}

check_k8s() {
  log_info "Checking Kubernetes is running..."
  if ! kubectl cluster-info &>/dev/null; then
    log_error "Cannot reach Kubernetes cluster."
    log_error "Please enable Kubernetes in Docker Desktop: Settings → Kubernetes → Enable Kubernetes"
    exit 1
  fi
  local ctx; ctx=$(kubectl config current-context)
  log_success "Kubernetes context: $ctx"
  if [[ "$ctx" != "docker-desktop" && "$ctx" != *"minikube"* ]]; then
    log_warn "Context '$ctx' does not look like Docker Desktop / Minikube."
    read -rp "Continue anyway? [y/N] " reply
    [[ "${reply,,}" == "y" ]] || exit 0
  fi
}

# ── Build images ──────────────────────────────────────────────────────────────
build_images() {
  log_info "Building Docker images..."
  docker build -t user-service:latest "$ROOT_DIR/services/user-service"
  log_success "user-service:latest built"
  docker build -t order-service:latest "$ROOT_DIR/services/order-service"
  log_success "order-service:latest built"
}

# ── Install NGINX Ingress ──────────────────────────────────────────────────────
install_ingress_nginx() {
  log_info "Installing ingress-nginx..."
  if helm status ingress-nginx -n ingress-nginx &>/dev/null; then
    log_success "ingress-nginx already installed — skipping"
    return
  fi
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx &>/dev/null || true
  helm repo update &>/dev/null
  helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.service.type=LoadBalancer \
    --wait --timeout 5m
  log_success "ingress-nginx installed"
}

# ── Deploy services ───────────────────────────────────────────────────────────
deploy_services() {
  log_info "Deploying microservices with Kustomize..."
  kubectl apply -k "$ROOT_DIR/k8s/overlays/local"
  log_success "Manifests applied"

  log_info "Waiting for deployments to be ready..."
  kubectl rollout status deployment/user-service  -n microservices --timeout=3m
  kubectl rollout status deployment/order-service -n microservices --timeout=3m
  log_success "All deployments ready"
}

# ── /etc/hosts ────────────────────────────────────────────────────────────────
print_hosts_instruction() {
  log_warn "Add this line to your /etc/hosts file (requires sudo):"
  echo ""
  echo "    127.0.0.1  microservices.local"
  echo ""
  echo "  Run: sudo sh -c 'echo \"127.0.0.1 microservices.local\" >> /etc/hosts'"
  echo ""
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}========================================================${NC}"
  echo -e "${GREEN}  Deployment Complete!${NC}"
  echo -e "${GREEN}========================================================${NC}"
  echo ""
  echo "  Service URLs (after adding /etc/hosts entry):"
  echo "    Users API:   http://microservices.local/api/v1/users"
  echo "    Orders API:  http://microservices.local/api/v1/orders"
  echo "    User Swagger: http://microservices.local/user-service/swagger-ui/index.html"
  echo "    Order Swagger: http://microservices.local/order-service/swagger-ui/index.html"
  echo ""
  echo "  Quick test:"
  echo '    curl -s http://microservices.local/api/v1/users | jq .'
  echo '    curl -s -X POST http://microservices.local/api/v1/users \'
  echo '      -H "Content-Type: application/json" \'
  echo '      -d '"'"'{"firstName":"Jane","lastName":"Doe","email":"jane@example.com"}'"'"' | jq .'
  echo ""
  echo "  View logs:"
  echo "    kubectl logs -f deploy/user-service  -n microservices"
  echo "    kubectl logs -f deploy/order-service -n microservices"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}  Microservices Local Setup${NC}"
  echo -e "${BLUE}================================================${NC}"
  check_prerequisites
  check_k8s
  build_images
  install_ingress_nginx
  deploy_services
  print_hosts_instruction
  print_summary
}

main "$@"
