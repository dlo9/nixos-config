#!/bin/sh

set -e

host="trident"
config="$host-sd-card"

#nix build --extra-sandbox-paths /sops-age-keys.txt=/var/sops-age-keys.txt "path:.#nixosConfigurations.$host.config.system.build.sdImage"
#nix --option sandbox-paths /var/sops-age-keys.txt build --impure "path:.#nixosConfigurations.$host.config.system.build.sdImage"

# Create a temporary directory
tmp=$(mktemp -d)

# Cleanup temporary directory on exit
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

sops -d --extract '["age-key"]["contents"]' "hosts/$host/secrets.yaml" > "$tmp/sops-age-keys.txt"

# Allow nixbld access to tmp
chown -R :nixbld "$tmp"
chmod -R g+r "$tmp"

nix build --option extra-sandbox-paths "/impure/sops-age-keys.txt=/$tmp/sops-age-keys.txt" --option builders "" "path:.#nixosConfigurations.$config.config.system.build.sdImage"
