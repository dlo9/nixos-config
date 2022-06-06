#!/bin/sh

set -e

# Install Nix with flake support
nix-env -iA nixos.nixFlakes

# Install script interpreter
nix-env -iA nixos.expect
