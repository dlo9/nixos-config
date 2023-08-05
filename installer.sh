#!/bin/sh

SOPS_KEY="$1"
HOSTNAME="$2"

# Enable nix-command and flakes
mkdir ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Install dependencies
nix profile install \
    nixpkgs#git \
    nixpkgs#sops