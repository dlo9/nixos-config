#!/use/bin/env bash

set -e

#nix-channel --add https://nixos.org/channels/nixos-21.11-small nixos
printf '%s\n' 'a' 'a' | passwd

nix-env -iA nixos.tmux nixos.nixFlakes
