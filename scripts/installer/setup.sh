#!/use/bin/env bash

set -e

#nix-channel --add https://nixos.org/channels/nixos-22.05-small nixos
printf '%s\n' 'a' 'a' | passwd

nix-env -iA nixos.tmux nixos.nixFlakes
