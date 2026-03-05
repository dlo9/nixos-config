#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

for dir in */; do
  echo "Pushing $dir..."
  (cd "$dir" && clasp push)
done
