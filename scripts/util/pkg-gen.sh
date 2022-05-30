#!/bin/sh

set -e

usage() {
    cat <<- EOF
    ./pkg-gen.sh <owner> <repo> [rev]
EOF
}

owner="$1"
repo="$2"
rev="${3:-HEAD}"

if echo "$owner" | grep "/" >/dev/null; then
    # User input was `owner/repo rev`, so split the first argument and shift
    rev="${repo:-HEAD}"
    repo="$(echo "$owner" | sed "s#.*/##")"
    owner="$(echo "$owner" | sed "s#/.*##")"
fi

if [ -z "$owner" ] || [ -z "$repo" ]; then
    usage
    exit 1
fi

rev="$(curl -s "https://api.github.com/repos/$owner/$repo/commits/$rev" | jq -r ".sha")"
hash="$(nix-prefetch-url --unpack https://github.com/$owner/$repo/archive/$rev.tar.gz 2>/dev/null)"

cat << EOF
pkgs.fetchFromGitHub {
    owner = "$owner";
    repo = "$repo";
    rev = "$rev";
    sha256 = "$hash";
};
EOF