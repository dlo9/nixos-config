#!/usr/bin/env bash

set -e

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

# Decrypt your private key from the password store and copy it to the temporary directory
install -d -m755 "$tmp/var"
sops -d --extract '["sops-key"]' install.secrets.yaml > "$tmp/var/sops-age-keys.txt"
chmod 600 "$tmp/var/sops-age-keys.txt"

install -d -m755 "$tmp/etc/nixos"
cp -r /etc/nixos "$tmp/etc"

# On the install image, run:
#  sudo passwd
nix run github:numtide/nixos-anywhere -- \
  --disk-encryption-keys /tmp/zfs.key <(sops -d --extract '["zfs-key"]' install.secrets.yaml) \
  --extra-files "$tmp" \
  --debug \
  --flake '.#installer-test' \
  -p 22222 root@localhost