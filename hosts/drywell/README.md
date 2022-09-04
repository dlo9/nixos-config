sudo drywell-partition
# Installation

1. Build the partitioning commands:

        sudo nixos-rebuild --update-input disko switch

2. Insert the USB
3. [Optional] If already installed, wipe the existing partition table:

        sudo wipefs -a /dev/disk/by-id/nvme-Force_MP500_17037932000122530025-part* /dev/disk/by-id/nvme-Force_MP500_17037932000122530025

4. Partition the USB

        sudo drywell-partition

5. Mount the USB

        sudo drywell-mount

6. Generate the hardware configuration

        # TODO: remove host swap from config
        ./generate-hardware-config.sh /mnt drywell

7. Sync the nix configuration

        sudo mkdir -p /mnt/etc/nixos
        sudo rsync -a --progress --delete --delete-excluded --exclude="*.log" /etc/nixos/ /mnt/etc/nixos

8. Install initrd keys (for SSH and secrets)

        sudo mkdir /mnt/var

        # SOPS_AGE_KEY must be set to the master key
        export SOPS_AGE_KEY="MASTER_KEY_HERE"

        sudo -E sh -c "sops -d --extract '[\"ssh-keys\"][\"host\"][\"rsa\"]' /etc/nixos/hosts/drywell/secrets.yaml > /mnt/var/ssh_host_rsa_key"

        sudo -E sh -c "sops -d --extract '[\"drywell\"][\"private\"]' /etc/nixos/sys/secrets/age-keys.yaml > /mnt/var/sops-age-keys.txt"

9. Install

        # Impure needed for `fromYaml` for some reason
        sudo nixos-install --flake "path:///mnt/etc/nixos#drywell" --root /mnt --impure

10. Unmount

        sudo swapoff /dev/disk/by-id/nvme-Force_MP500_17037932000122530025-part3
        sudo umount /mnt/boot/efi0
        sudo zpool export upool
