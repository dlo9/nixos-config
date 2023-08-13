#!/usr/bin/env bash

set -e

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

system=:$(basename "$(pwd)"):
user="root"
port="22"
host="192.168.1.25"

# Copy the hardware config here
ssh -p "$port" "$user@$host" "nixos-generate-config --show-hardware-config --no-filesystems" > hardware/generated.nix

# Decrypt your private key from the password store and copy it to the temporary directory
install -d -m755 "$tmp/var"
sops -d --extract '["sops-key"]' install.secrets.yaml > "$tmp/var/sops-age-keys.txt"
chmod 600 "$tmp/var/sops-age-keys.txt"

install -d -m755 "$tmp/etc"
cp -r /etc/nixos "$tmp/etc"

On the install image, run:
 sudo passwd
nix run github:numtide/nixos-anywhere -- \
  --disk-encryption-keys /tmp/zfs.key <(sops -d --extract '["zfs-key"]' install.secrets.yaml) \
  --extra-files "$tmp" \
  --debug \
  --flake "path:.#$system" \
  root@192.168.1.25