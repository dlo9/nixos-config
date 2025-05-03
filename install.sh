#!/bin/sh

set -e

host="wyse"
remote_host="nixos"
remote_user="nixos"
remote_port="22"
remote_password="nixos"

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

# Decrypt host age private key from the password store and copy it to the temporary directory,
# which will be copied to the new root
install -d -m755 "$tmp/root/var"
sops -d --extract '["age-key"]["contents"]' "hosts/$host/secrets.yaml" > "$tmp/root/var/sops-age-keys.txt"
chmod 600 "$tmp/root/var/sops-age-keys.txt"

# Decrypt the root zfs encryption key from the password store and copy it to the temporary directory,
# which will be copied to the installation image but not the new root
sops -d --extract '["zfs-root-encryption-key"]["contents"]' "hosts/$host/secrets.yaml" > "$tmp/zfs.key"

# Copy this nixos configuration to the temporary directory
# TODO: is this necessary, or does nixos-anywhere copy the whole repo?
#install -d -m755 "$tmp/root/etc"
#cp -r . "$tmp/root/etc"

# On the install image, run:
#  sudo passwd
# nix run github:nix-community/nixos-anywhere -- \
env SSHPASS="$remote_password" nix run nixpkgs#nixos-anywhere -- \
  --disk-encryption-keys /tmp/zfs.key "$tmp/zfs.key" \
  --debug \
  --env-password \
  --flake ".#$host" \
  --generate-hardware-config nixos-generate-config "hosts/$host/hardware/generated.nix" \
  -p "$remote_port" \
  --target-host "$remote_user@$remote_host" \
  --extra-files "$tmp/root/"
  # --kexec "$(nix build --print-out-paths "github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-unstable-noninteractive")/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz" \
