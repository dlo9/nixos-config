#!/bin/sh

set -e

get_commit() {
    pr_number="$1"
    curl -Ls "https://github.com/NixOS/nixpkgs/pull/$pr_number/commits" | rg -o 'commit-details-[^"]+' | sed 's/commit-details-//' | tail -1
}

get_commit_file() {
    pr_number="$1"
    file_name="$2"

    commit="$(get_commit "$pr_number")"
    curl -Ls "https://raw.githubusercontent.com/NixOS/nixpkgs/$commit/$file_name"
}

# https://github.com/NixOS/nixpkgs/pull/308097
get_commit_file 308097 pkgs/by-name/al/alvr/fix-finding-libs.patch > pkgs/alvr/fix-finding-libs.patch
get_commit_file 308097 pkgs/by-name/al/alvr/Cargo.lock > pkgs/alvr/Cargo.lock
get_commit_file 308097 pkgs/by-name/al/alvr/package.nix > pkgs/alvr/package.nix
sed -i '/patches = \[/a\    ./intel-gpu.patch' pkgs/alvr/package.nix

# https://github.com/NixOS/nixpkgs/pull/316975
get_commit_file 316975 nixos/modules/services/video/wivrn.nix > hosts/cuttlefish/services/wivrn/module.nix
get_commit_file 316975 pkgs/by-name/wi/wivrn/package.nix > pkgs/wivrn.nix