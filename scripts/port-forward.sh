#!/bin/bash
# =============================================================================
# port-forward.sh — Port-forward services for direct local access
# =============================================================================
set -euo pipefail

echo "Starting port-forwards..."
echo "  user-service  → http://localhost:8081"
echo "  order-service → http://localhost:8082"
echo ""
echo "Press Ctrl+C to stop all port-forwards"
echo ""

cleanup() {
  echo ""
  echo "Stopping port-forwards..."
  kill "${PF_PIDS[@]}" 2>/dev/null || true
}
trap cleanup SIGINT SIGTERM

PF_PIDS=()

kubectl port-forward svc/user-service  8081:80 -n microservices &
PF_PIDS+=($!)

kubectl port-forward svc/order-service 8082:80 -n microservices &
PF_PIDS+=($!)

wait
