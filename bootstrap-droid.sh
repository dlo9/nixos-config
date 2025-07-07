#!/bin/sh

set -e

cleanup() {
  rm /tmp/age-key
}

trap cleanup EXIT

# On the phone, start SSH
# nix run github:dlo9/nixos-config#nix-on-droid-ssh

# Extract age key
sops -d --extract '["age-key"]["contents"]' hosts/pixie/secrets.yaml  > /tmp/age-key

# Copy key to device
scp -P 8022 -O -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/age-key nix-on-droid@google-pixel-6:./.config/sops-age-keys.txt

# Deploy
nix run nixpkgs#deploy-rs -- --ssh-opts "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --skip-checks -k .#pixie -- --impure
