#!/bin/bash
# =============================================================================
# teardown-local.sh — Remove all local microservices resources
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()    { echo -e "\033[0;34m[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

log_warn "This will delete ALL microservices resources from your local cluster."
read -rp "Are you sure? [y/N] " reply
[[ "${reply,,}" == "y" ]] || { log_info "Aborted."; exit 0; }

log_info "Removing microservices..."
kubectl delete -k "$ROOT_DIR/k8s/overlays/local" --ignore-not-found=true
log_success "Microservices removed"

log_info "Removing ingress-nginx..."
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
kubectl delete namespace ingress-nginx --ignore-not-found=true
log_success "ingress-nginx removed"

kubectl delete namespace microservices --ignore-not-found=true
log_success "microservices namespace removed"

log_success "Teardown complete."
