#!/usr/bin/env bash

set -e

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

system="$(basename "$(pwd)")"
user="root"
port="22"
host="192.168.1.132"

# Copy the hardware config here
ssh -p "$port" "$user@$host" "nixos-generate-config --show-hardware-config --no-filesystems" > hardware/generated.nix

# Decrypt your private key from the password store and copy it to the temporary directory
install -d -m755 "$tmp/var"
sops -d --extract '["age-key"]["contents"]' secrets.yaml > "$tmp/var/sops-age-keys.txt"
chmod 600 "$tmp/var/sops-age-keys.txt"

# Copy flake into temporary directory
# This lets the host easily change its own configuration later
install -d -m755 "$tmp/etc"
cp -r /etc/nixos "$tmp/etc"

# On the install image, run:
#   sudo passwd

# Install rsync https://github.com/nix-community/nixos-anywhere/issues/260
ssh -p "$port" "$user@$host" nix-env -iA nixos.rsync
nix run github:numtide/nixos-anywhere -- \
  --disk-encryption-keys /tmp/zfs.key <(sops -d --extract '["zfs-key"]' secrets.yaml) \
  --extra-files "$tmp" \
  --debug \
  --flake "$PWD#$system" \
  "$user@$host"

# TODO: These steps had to be done manually
# sudo chown -R david:users /home/david/
# sudo chown david:users /home/david/.ssh/