- Show battery life in waybar (use `acpi -b`?)



- Test auto-update with flake
- Add root user config?
- Nix-store dataset
- Review [sway addons](https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway)
- Test [qddcswitch](https://codeberg.org/Okxa/qddcswitch)
- quotebrowser
  - adblock
- Build `wrap`
- Use [more modern tools](https://github.com/ibraheemdev/modern-unix)
- Test `neovim`
- Set SSH user keys (in secret)?
- QT styling
- Flameshot
- `services.random-background`
- Admin email notifications:
  - On upgrade
  - ZFS send/recv errors
  - scrub errors
- Samba mounts (`systemd.user.mounts`?)
- mosh

- [Nix flake](https://hoverbear.org/blog/a-flake-for-your-crate/) for rust projects (e.g. wrap)
- [nix-direnv](https://github.com/nix-community/nix-direnv)
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
