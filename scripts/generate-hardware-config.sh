#!/bin/sh

nixos-generate-config --show-hardware-config | nixpkgs-fmt > "/etc/nixos/hardware/$(hostname).nix"
