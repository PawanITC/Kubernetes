#!/bin/bash
# =============================================================================
# setup-argocd.sh — Install ArgoCD and deploy the app-of-apps
# =============================================================================
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

log_info "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log_info "Waiting for ArgoCD to be ready (this takes ~2 minutes)..."
kubectl wait --for=condition=available --timeout=5m \
  deployment/argocd-server \
  deployment/argocd-repo-server \
  deployment/argocd-application-controller \
  -n argocd
log_success "ArgoCD is ready"

log_info "Exposing ArgoCD server as LoadBalancer..."
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

log_info "Fetching initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

log_info "Deploying app-of-apps..."
kubectl apply -f "$ROOT_DIR/argocd/project.yaml"
kubectl apply -f "$ROOT_DIR/argocd/app-of-apps.yaml"
log_success "App-of-apps deployed"

echo ""
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}  ArgoCD Setup Complete!${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo "  ArgoCD URL:      https://localhost:8080  (after port-forward below)"
echo "  Username:        admin"
echo "  Password:        $ARGOCD_PASSWORD"
echo ""
echo "  Port-forward command:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "  Or wait for LoadBalancer IP:"
echo "    kubectl get svc argocd-server -n argocd"
echo ""
log_warn "Change the default password after first login!"
