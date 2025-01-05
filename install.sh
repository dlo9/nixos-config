#!/bin/sh

set -e

host="trident"
remote_user="pi"
remote_port="22"

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

# Decrypt your private key from the password store and copy it to the temporary directory
install -d -m755 "$tmp/var"
sops -d --extract '["age-key"]["contents"]' "hosts/$host/secrets.yaml" > "$tmp/var/sops-age-keys.txt"
chmod 600 "$tmp/var/sops-age-keys.txt"

#install -d -m755 "$tmp/etc"
#cp -r /etc/nixos "$tmp/etc"

# On the install image, run:
#  sudo passwd
nix run github:nix-community/nixos-anywhere -- \
  --disk-encryption-keys /tmp/zfs.key "$tmp/var/sops-age-keys.txt" \
  --debug \
  --flake ".#$host" \
  --generate-hardware-config nixos-generate-config "hosts/$host/hardware/generated.nix" \
  --kexec "$(nix build --print-out-paths "github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-unstable-noninteractive")/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz" \
  -p "$remote_port" \
  --target-host "$remote_user@$host"
#  --extra-files "$tmp" \
