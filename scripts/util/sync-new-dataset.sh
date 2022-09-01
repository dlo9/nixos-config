#!/bin/sh

set -e

mountPoint="$1"
if [ -z "$mountPoint" ]; then
  echo "./sync-new-dataset.sh <new mountpoint>"
  exit 1
fi

if ! mountpoint "$mountPoint" > /dev/null; then
  echo "ERROR: $mountPoint is not a mountpoint"
  exit 1
fi

# Get the parent mount
parent="$(dirname "$mountPoint")"
base="$(basename "$mountPoint")"

# Bind mount it
bindMount="/mnt"
mountpoint "$bindMount" > /dev/null && umount "$bindMount"
mount --bind "$parent" "$bindMount"

# Sync it
rsync -aAXUH --progress "$bindMount/$base/." "$mountPoint"

# Cleanup
find "$bindMount/$base" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
umount "$bindMount"



