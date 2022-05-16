# System Dotfiles

This used to be a repository for system dotfiles, but have now been replaced by the nix configurations for all my machines.

# Adding a new host

## Installing
TODO

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
   cd /etc/nixos
   ./generate-hardware-config.sh
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