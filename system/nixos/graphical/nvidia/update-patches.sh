#!/bin/sh

set -e

origin="https://raw.githubusercontent.com/keylase/nvidia-patch/master"
nvfbcOrigin="$origin/patch-fbc.sh"
nvencOrigin="$origin/patch.sh"

parsePatchFile() {
    awk -F "[\"']" '$2 ~ /[0-9]+\.[0-9]+/'
}

curl -Lsf "$nvfbcOrigin" | awk -f update-patches.awk > nvfbc.nix
curl -Lsf "$nvencOrigin" | awk -f update-patches.awk > nvenc.nix
