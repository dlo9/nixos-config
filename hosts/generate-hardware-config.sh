#!/bin/sh

root="${1:-/}"
hostname="${2:-$(hostname)}"
config="/etc/nixos/hosts/$hostname/hardware.nix"

touch "$config"

# Must use `sudo` so that all mounts are visible
sudo nixos-generate-config --root "$root" --show-hardware-config | \
  ./process-hardware-config.awk | \
  nixpkgs-fmt > "$config"
