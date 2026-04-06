#!/bin/bash
# =============================================================================
# build-images.sh — Build and optionally push Docker images
# Usage: ./scripts/build-images.sh [--push] [--tag <tag>] [--registry <registry>]
# =============================================================================
set -euo pipefail

PUSH=false
TAG="latest"
REGISTRY="ghcr.io/PawanITC"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push)     PUSH=true ;;
    --tag)      TAG="$2"; shift ;;
    --registry) REGISTRY="$2"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

build_and_push() {
  local name="$1"
  local context="$2"
  local full_image="${REGISTRY}/${name}:${TAG}"

  echo "Building $full_image..."
  docker build --platform linux/amd64 -t "$full_image" "$context"
  echo "  Tagged: $full_image"

  if [[ "$TAG" != "latest" ]]; then
    docker tag "$full_image" "${REGISTRY}/${name}:latest"
    echo "  Tagged: ${REGISTRY}/${name}:latest"
  fi

  if [[ "$PUSH" == "true" ]]; then
    echo "Pushing $full_image..."
    docker push "$full_image"
    [[ "$TAG" != "latest" ]] && docker push "${REGISTRY}/${name}:latest"
    echo "  Pushed: $full_image"
  fi
}

build_and_push "user-service"  "$ROOT_DIR/services/user-service"
build_and_push "order-service" "$ROOT_DIR/services/order-service"

echo ""
echo "Done. Images built with tag: $TAG"
[[ "$PUSH" == "true" ]] && echo "Images pushed to: $REGISTRY"
