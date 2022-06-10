#!/bin/sh

set -e

nix-env -q

echo "Searching expect" && which expect || true
echo "Searching git" && which git || true
echo "Searching sops" && which sops || true

# Install Nix with flake support
nix-env -iA nixos.nixFlakes

# Install script interpreter
nix-env -iA nixos.expect

# Git makes flake support easier
nix-env -iA nixos.git

# Secrets decryption
nix-env -iA nixos.sops
