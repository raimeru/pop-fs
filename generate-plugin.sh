#!/usr/bin/env bash
set -euo pipefail

DISTRO_VERSION="24.04 LTS"
DISTRO_CODENAME="noble"

TARBALL="popos-arm64-rootfs.tar.xz"
RUN_NUMBER="${1}"

SHA256=$(sha256sum "$TARBALL" | awk '{ print $1 }')
RELEASE_TAG="popos-arm64-${RUN_NUMBER}"
REPO="${GITHUB_REPOSITORY}"

cat > popos.sh <<EOF
DISTRO_NAME="Pop!_OS ${DISTRO_VERSION}"
DISTRO_COMMENT="Pop!_OS ${DISTRO_CODENAME} arm64"

TARBALL_URL['aarch64']="https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${TARBALL}"
TARBALL_SHA256['aarch64']="${SHA256}"
EOF

echo "Plugin generated:"
cat popos.sh