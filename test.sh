#!/bin/bash
set -euo pipefail

VM_NAME="dockerhost"
DOCKER_CONTEXT_NAME="docker-parallels"

echo "👉 Bringing up the Docker VM..."
docker vagrant destroy -f || true
docker vagrant up

echo "✅ Checking that Docker context is active..."
if ! docker context inspect "$DOCKER_CONTEXT_NAME" &> /dev/null; then
    echo "❌ Docker context $DOCKER_CONTEXT_NAME not found!"
    exit 1
fi

ACTIVE_CONTEXT=$(docker context show)
if [[ "$ACTIVE_CONTEXT" != "$DOCKER_CONTEXT_NAME" ]]; then
    echo "❌ Docker context not active: expected '$DOCKER_CONTEXT_NAME', got '$ACTIVE_CONTEXT'"
    exit 1
fi

echo "✅ Running test container..."
docker run --rm --platform=linux/arm64 alpine uname -m | grep -q aarch64 && echo "✅ QEMU binfmt for aarch64 works!"
docker run --rm --platform=linux/amd64 alpine uname -m | grep -q x86_64 && echo "✅ QEMU binfmt for y86_64 works!"

echo "✅ Validating VM internals..."
#vagrant ssh "$VM_NAME" -c "which docker && which mkcert" | grep -q docker || { echo "❌ Docker not found in VM"; exit 1; }
docker vagrant ssh -c "sudo bash /vagrant/provision.sh && echo '✅ Provisioning succeeded again.'"


echo "🎉 All checks passed."
