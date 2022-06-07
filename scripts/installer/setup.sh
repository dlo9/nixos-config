#!/bin/sh

set -e

# Install Nix with flake support
nix-env -iA nixos.nixFlakes

# Install script interpreter
nix-env -iA nixos.expect

# Git makes flake support easier
nix-env -iA nixos.git

# Secrets decryption
nix-env -iA nixos.sops
