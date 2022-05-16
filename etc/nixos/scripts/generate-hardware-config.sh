#!/bin/sh

nixos-generate-config --show-hardware-config > "/etc/nixos/hardware/$(hostname).nix"
