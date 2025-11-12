- Consolidate font settings

- Use [more modern tools](https://github.com/ibraheemdev/modern-unix)
- QT styling
- `services.random-background`

- Partitioning:
  ```sh
  # SSD
  sudo zpool create \
      -o ashift=12 \
      -o autotrim=on \
      -o autoreplace=on \
      -o autoexpand=on \
      -O compression=zstd \
      -O atime=off \
      -O canmount=off \
      -O xattr=sa \
      -O dnodesize=auto
      -O normalization=formD \
      -O acltype=posix \
      -O encryption=aes-256-gcm \
      -O keyformat=passphrase \
      -O keylocation=file:///zfs/slow.key \
      slow
  ```

# 25.11 Release
- Look at cloudflare-ddns to replace go-dns
- Remove system.rebuild.enableNg
- Look at system.nixos-init.enable
- Caddy/k8s depend on `acme-{certname}.service`?
- systemd.extraConfig changed to systemd.settings.Manager
- systemd.watchdog esttings changed to use systemd.settings.Manager
- ssh agent removed from gnome-keyring (services.gnome.gcr-ssh-agent.enable)
