#!/bin/sh

hardware_dir="/etc/nixos/hardware/"

mkdir -p "$hardware_dir"
nixos-generate-config --show-hardware-config > "$hardware_dir/$(hostname).nix"