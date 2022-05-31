#!/use/bin/env bash

password=password

echo "Generating SSH initrd key"
mkdir -p /mnt/etc/ssh/
if [ ! -f /mnt/etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -N "" -f /mnt/etc/ssh/ssh_host_rsa_key
fi

echo "Copying configuration"
mkdir -p /mnt/etc/nixos/
rsync -a config/ /mnt/etc/nixos/

echo "Generating hardware config"
nixos-generate-config --root /mnt

echo "Installing"
nix-env -iA nixos.nixFlakes
#printf '%s\n' "$password" "$password" | nixos-install -v --show-trace --experimental-features="nix-command flakes" --flake "/mnt/etc/nixos/flake.nix#ace" --root /mnt
printf '%s\n' "$password" "$password" | nixos-install -v --show-trace --flake "/mnt/etc/nixos#ace" --root /mnt
#nix-shell -p nixUnstable --run "nix build /mnt/etc/nixos/flake#nisoxConfigurations.ace.config.system.build.toplevel"
#printf '%s\n' "$password" "$password" | nixos-install -v --show-trace --root /mnt
#nix build /mnt/etc/nixos/flake#nixosConfigurations.ace.config.system.build.toplevel
#printf '%s\n' "$password" "$password" | nixos-install -v --show-trace --root /mnt --system result

# TODO: Install fails with ‘/mnt/tmp.coRUoqzl1P/initrd-secrets.XXXXXXXXXX’: No such file or directory
# https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/Root%20on%20ZFS/4-system-installation.html#set-root-password
# https://github.com/NixOS/nixpkgs/issues/157989
# nixos-enter --root /mnt -- nixos-rebuild -v --show-trace --option sandbox false boot
