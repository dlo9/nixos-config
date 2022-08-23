#!/bin/sh

config="./$(hostname)/hardware.nix"

# Must use `sudo` so that all mounts are visible
sudo nixos-generate-config --show-hardware-config | ./process-hardware-config.awk | \
  nixpkgs-fmt > "$config"

chown $USER:users "$config"
