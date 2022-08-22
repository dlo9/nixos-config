#!/bin/sh

nixos-generate-config --show-hardware-config | \
  sed '/# networking.*/d' | \
  nixpkgs-fmt > "./$(hostname)/hardware.nix"
