#!/bin/sh

nixos-generate-config --show-hardware-config | \
  sed '/# networking.*/d' | \
  nixpkgs-fmt > "/etc/nixos/hardware/$(hostname).nix"
