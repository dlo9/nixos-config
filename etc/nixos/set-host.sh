#!/bin/sh
#
# Installs the proper config files for a host

host="$1"
if [ -z "$host" ]; then
  echo "usage: ./set-host.sh <host>"
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: script must be run with root privileges"
  exit 1
fi

ln -sf "hosts/$host/configuration.nix"
ln -sf "hosts/$host/hardware-configuration.nix"
