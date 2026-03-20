#!/usr/bin/env bash
set -euo pipefail

DISTRO_CODENAME="noble"

mkdir -p /root/.gnupg
chmod 700 /root/.gnupg

gpg --no-default-keyring \
  --keyring /usr/share/keyrings/ubuntu-archive.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys 871920D1991BC93C

gpg --no-default-keyring \
  --keyring /tmp/pop-os-temp.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys 204DD8AEC33A7AFF

gpg --no-default-keyring \
  --keyring /tmp/pop-os-temp.gpg \
  --export 204DD8AEC33A7AFF \
  | tee /usr/share/keyrings/pop-os.gpg > /dev/null

debootstrap \
  --arch=arm64 \
  --keyring=/usr/share/keyrings/ubuntu-archive.gpg \
  --include=apt,bash,coreutils,systemd,locales,sudo,wget,curl \
  "$DISTRO_CODENAME" \
  ./rootfs \
  http://ports.ubuntu.com/ubuntu-ports

cp /usr/share/keyrings/pop-os.gpg ./rootfs/etc/apt/trusted.gpg.d/pop-os.gpg
cp /usr/share/keyrings/pop-os.gpg ./rootfs/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg

rm -f ./rootfs/etc/resolv.conf
echo "nameserver 1.1.1.1" > ./rootfs/etc/resolv.conf

cat > ./rootfs/etc/apt/sources.list <<EOF
deb http://ports.ubuntu.com/ubuntu-ports ${DISTRO_CODENAME} main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports ${DISTRO_CODENAME}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports ${DISTRO_CODENAME}-security main restricted universe multiverse
EOF

cat > ./rootfs/etc/apt/sources.list.d/pop-os-release.sources <<EOF
Types: deb
URIs: http://apt.pop-os.org/release
Suites: ${DISTRO_CODENAME}
Components: main
Signed-By: /etc/apt/trusted.gpg.d/pop-os.gpg
EOF

systemd-nspawn -D ./rootfs bash -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get upgrade -y
  apt-get install -y pop-default-settings

  if [ -f /etc/apt/sources.list.d/pop-os-apps.sources ]; then
    sed -i "/^$/d" /etc/apt/sources.list.d/pop-os-apps.sources
    sed -i "/^Signed-By:/d" /etc/apt/sources.list.d/pop-os-apps.sources
    echo "Signed-By: /etc/apt/trusted.gpg.d/pop-os.gpg" \
      >> /etc/apt/sources.list.d/pop-os-apps.sources
  fi

  # Remove apt.pop-os.org/ubuntu — amd64 only
  for f in /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list; do
    grep -q "apt.pop-os.org/ubuntu" "$f" 2>/dev/null && rm -f "$f"
  done

  apt-get update
  apt-get install -y \
    pop-fonts \
    pop-icon-theme \
    pop-gtk-theme \
    ca-certificates \
    bash-completion

  apt-get clean
  rm -rf /var/lib/apt/lists/*
'