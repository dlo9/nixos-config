#!/bin/sh

root="${1:-/}"
hostname="${2:-$(hostname)}"
dir="$(dirname "$0")"
config="$dir/$hostname/hardware.nix"

touch "$config"

if [ "$root" != "/" ]; then
  extraArgs="--root $root"
fi

# Must use `sudo` so that all mounts are visible
sudo nixos-generate-config $extraArgs --show-hardware-config | \
  "$dir/process-hardware-config.awk" | \
  nixpkgs-fmt > "$config"
