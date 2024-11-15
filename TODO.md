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
