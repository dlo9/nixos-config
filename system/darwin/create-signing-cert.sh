#!/usr/bin/env bash
# One-time setup, run once per machine (or to rotate the key).
#
# macOS TCC (the permission system behind Accessibility and Full Disk Access)
# pins a permission grant to the code-signing requirement of the binary. Nix
# signs binaries ad-hoc, whose requirement is pinned to the exact cdhash, so
# every rebuild produces a "new" binary and the permission is revoked.
#
# This creates a stable self-signed code-signing key+certificate and stores it,
# encrypted, as the `codesign-key` sops secret for this host. codesign-wm (the
# nix-darwin launchd agent) decrypts it at runtime and re-signs
# yabai/skhd/Alacritty with it via rcodesign on every rebuild, so the
# requirement TCC stored keeps matching and the permission persists. The grant
# references the certificate, not the cdhash, so it even survives version
# upgrades.
#
# Unlike a keychain identity, the private key never enters the nix store: it
# lives only in the encrypted sops file and is decrypted to a user-owned
# /run/secrets path at runtime. No keychain, no trust settings, no sudo.
#
# Usage: create-signing-cert.sh [secrets-file] [owner]
#   secrets-file  defaults to hosts/<LocalHostName>/secrets.yaml
#   owner         user that must read the key at runtime (defaults to $USER)
#
# Requires rcodesign, sops, and jq on PATH, e.g.:
#   nix shell nixpkgs#rcodesign nixpkgs#sops nixpkgs#jq -c ./system/darwin/create-signing-cert.sh
set -euo pipefail

SECRET_NAME="codesign-key"
SECRETS_FILE="${1:-hosts/$(scutil --get LocalHostName 2>/dev/null || hostname -s)/secrets.yaml}"
OWNER="${2:-$USER}"

: "${SOPS_AGE_KEY_FILE:=/var/sops-age-keys.txt}"
export SOPS_AGE_KEY_FILE

if [ ! -f "$SECRETS_FILE" ]; then
  echo "Secrets file not found: $SECRETS_FILE" >&2
  exit 1
fi

for cmd in rcodesign sops jq; do
  command -v "$cmd" >/dev/null || { echo "'$cmd' not found on PATH." >&2; exit 1; }
done

if sops -d --extract "[\"$SECRET_NAME\"][\"contents\"]" "$SECRETS_FILE" >/dev/null 2>&1; then
  echo "Secret '$SECRET_NAME' already exists in $SECRETS_FILE. Nothing to do."
  echo "(Delete that key from the file first if you want to rotate it.)"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Generating stable self-signed code-signing key+certificate..."
rcodesign generate-self-signed-certificate \
  --person-name "$SECRET_NAME" \
  --validity-days 7300 \
  --pem-unified-file "$tmp/unified.pem" >/dev/null

echo "Encrypting into $SECRETS_FILE as '$SECRET_NAME' (owner: $OWNER)..."
sops set "$SECRETS_FILE" "[\"$SECRET_NAME\"][\"sopsNix\"][\"owner\"]" "\"$OWNER\""
sops set "$SECRETS_FILE" "[\"$SECRET_NAME\"][\"contents\"]" "$(jq -Rs . < "$tmp/unified.pem")"

echo
echo "Done. Now run 'darwin-rebuild switch', then grant Accessibility (yabai/skhd)"
echo "and Full Disk Access (Alacritty) one final time. They will persist from now on."
