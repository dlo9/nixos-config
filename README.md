# System Dotfiles

This used to be a repository for system dotfiles, but have now been replaced by the nix configurations for all my machines.

# Adding a new host

## Installing
### The fancy way
This method installs the NixOS configuration from this repo directly -- it's fancy, but
makes it more difficult to manage long-term on the host.
```sh
nixos-rebuild switch --flake 'github:dlo9/system-dotfiles'
```

### The maintainable way
This method installs this NixOS flake by cloning the repo first, which makes it easy to
reference and keep updated
```sh
sudo git clone https://github.com/dlo9/system-dotfiles /etc/nixos
sudo chown -R USER:users /etc/nixos
sudo chown root:root /etc/nixos
```

## Configuration
1. On the host, clone this flake into the nixos configuration directory:
   ```sh
   # This working directory will be assumed for the rest of the README
   cd /etc/nixos

   git clone https://github.com/dlo9/system-dotfiles.git
   ```

2. Add a configuration for the host:
   ```sh
   vim flake.nix
   ```

3. Generate a hardware configuration:
   ```sh
   ./scripts/generate-hardware-config.sh
   git add .
   ```

## Secrets
1. On the host, generate an age public and private keypair for the host so that its secrets can be stored in git:
   ```sh
   # Generate the key
   sudo age-keygen > /var/sops-age/keys.txt
   sudo chmod 600 /var/sops-age/keys.txt

   # Add it to the root user's SOPS keys so that files can be edited with `sudo sops <file>`
   sudo mkdir -p /root/.config/sops/age
   sudo ln -s /var/sops-age-keys.txt /root/.config/sops/age/nix.txt
   ```

2. Copy the keys into git:
   ```sh
   env SOPS_AGE_KEY=<bitwarden age key> sops ./secrets/age-keys.yaml
   ```

3. Add the public key to the `shared` secrets file:
   ```sh
   vim ./.sops.yaml
   ```

4. Add a host secret file:
   ```sh
   vim ./.sops.yaml
   touch "./secrets/hosts/$(hostname).yaml"
   ```

5. Generate secrets for the host:
   ```sh
   # SSH keys
   for type in ed25519 rsa; do
     mkdir -p "/tmp/ssh-keys"
     ssh-keygen -t "$type" -C "root@$(hostname)" -f "/tmp/ssh-keys/$type"
   done
   ```

6. Copy secrets into the host secret file:
   ```sh
   sudo sops "./secrets/hosts/$(hostname).yaml"

   # SSH keys
   cat /tmp/ssh-keys/ed25519.pub | wc-copy
   cat /tmp/ssh-keys/ed25519 | wc-copy
   cat /tmp/ssh-keys/rsa.pub | wc-copy
   cat /tmp/ssh-keys/rsa | wc-copy
   ```

# Help
This section contains information I frequently have to look up, and want an easier way to find.

## Common Nix Links
- [Nix package search](https://search.nixos.org/options)
- [NixOS options search](https://search.nixos.org/packages)
- [Home manager options](https://rycee.gitlab.io/home-manager/options.html)
- [NixOS wiki](https://nixos.wiki/wiki)
- [Cheatsheet](https://nixos.wiki/wiki/Cheatsheet)
- [Cookbook](https://nixos.wiki/wiki/Nix_Cookbook)
- [Builtin and lib functions](https://teu5us.github.io/nix-lib.html)
- [Trivial builders](https://ryantm.github.io/nixpkgs/builders/trivial-builders)

## Special files
- `/run/current-system` - the currently running system profile
- `/nix/var/nix/profiles/system` - the default boot profile
- `/nix/var/nix/profiles/per-user/` - user profiles

## Cheatsheet
### Configuration switching
```sh
# Build and apply the configuration at `/etc/nixos` as the current and default boot profiles
nixos-rebuild switch

# Build and aplly the configuration as the current profile only. The default boot profile is unchanged
# and will be run when the system is rebooted
nixos-rebuild test

# Build and apply the configuration, but without updating the package manager first. Slightly faster than
# the above
nixos-rebuild test --fast

# Check the configuration for errors, without building it. This is the fastest way of hacking a complete system
# https://github.com/NixOS/nix/issues/3908
nix eval "/etc/nixos#nixosConfigurations.$(hostname).config.system.build.toplevel.drvPath"
```

### Nix store
```sh
# Delete all old generations for all profiles
nix-collect-garbage --delete-old

# Delete generations older than 1 week for all profiles
nix-collect-garbage --delete-older-than 7d

# Get the store path for a package
nix eval --raw 'nixpkgs#OVMF.version'   # Uses latest `nixpkgs` flake to get the latest version for package `OVMF`
nix eval --raw -f '<nixpkgs>' OVMF      # Uses system `nixpkgs` to get the nix store path for package output
nix eval --raw -f '<nixpkgs>' OVMF.out  # Same as above, just more verbose
nix eval --raw -f '<nixpkgs>' OVMF.fd   # Gets path of the alternate output `fd`
```

### Networking
```sh
# View network controllers
lspci -v | grep -iA8 'network\|ethernet'

# Manually connect to wireless network (wifi)
wifi_name="<WIFI_NAME>"
wifi_password="<WIFI_PASSWORD>"
wifi_interface="$(ip link show | awk -F '[ \t:]+' ' $2 ~ /^w/ { print $2 }')"

wpa_passphrase "$wifi_name" "$wifi_password" > /tmp/wifi_config
wpa_supplicant -i "$wifi_interface" -c /tmp/wifi_config
rm /tmp/wifi_config

# Connect with DHCP on an interface
dhcpcd "$NETWORK_INTERFACE"
```

### Miscellaneous
```sh
```
