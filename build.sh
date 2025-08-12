#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="seathegood/unifi-controller"
VERSION=""
CLEAN=false
PUSH=false

# Detect the local docker platform for --load builds
_detect_local_platform() {
  case "$(uname -m)" in
    x86_64) echo "linux/amd64" ;;
    arm64|aarch64) echo "linux/arm64" ;;
    *) echo "linux/amd64" ;;
  esac
}
LOCAL_PLATFORM="$(_detect_local_platform)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    --push)
      PUSH=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "Usage: $0 --version X.Y.Z [--clean] [--push]"
  exit 1
fi

if $CLEAN; then
  echo "Cleaning build cache..."
  docker builder prune --force
fi

echo "Building Docker image for version ${VERSION}..."

BUILD_CMD=(
  docker buildx build
  --tag "${IMAGE_NAME}:${VERSION}"
  --tag "${IMAGE_NAME}:latest"
  --build-arg UNIFI_CONTROLLER_VERSION="${VERSION}"
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  --build-arg VCS_REF="$(git rev-parse --short HEAD)"
  --label org.opencontainers.image.revision="$(git rev-parse --short HEAD)"
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
)

if $PUSH; then
  BUILD_CMD+=(--platform linux/amd64,linux/arm64 --push)
else
  echo "Local build: using platform ${LOCAL_PLATFORM} with --load"
  BUILD_CMD+=(--platform "${LOCAL_PLATFORM}" --load)
fi

BUILD_CMD+=(.)

"${BUILD_CMD[@]}"

echo "Build complete."