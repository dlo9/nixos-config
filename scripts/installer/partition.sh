#!/use/bin/env bash
# To run: sudo bash ./partition.sh

set -e

##################
##### INPUTS #####
##################

vdev_type=  # Defaults to `disk` or `mirror` if empty, depending on disk count

disks=(
  #/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D
  /dev/disk/by-id/ata-QEMU_HARDDISK_QM00001
  /dev/disk/by-id/ata-QEMU_HARDDISK_QM00002
)

users=(
  david
)

password=password

efi_size=500M
swap_size=2G

######################
##### VALIDATION #####
######################

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: must be run as root"
  exit 1
fi

###########################################
##### Partitioning & basic formatting #####
###########################################

refresh() {
  local disk="$1"

  sleep 1
  partprobe "$disk"
  sleep 1
}

echo "Unmounting"
if [ -d /mnt/boot/efi1 ]; then
  umount /mnt/boot/efi* || true
fi

zpool export -a || true
for disk in "${disks[@]}"; do
  swapoff "$disk-part2" || true
done

for disk in "${disks[@]}"; do
  echo "Erasing disk $disk"
  #wipefs -a "$disk"* || sleep 3 && wipefs -a "$disk"*
  wipefs -a "$disk-"* || true
  wipefs -a "$disk"
  refresh "$disk"

  # Create partition table
  echo "Partitioning disk $disk"
  sgdisk --zap-all "$disk"
  refresh "$disk"

  # EFI Boot (partition 1) -- 1GB
  echo "Creating EFI partition"
  sgdisk --new 1:1M:+$efi_size --typecode 1:EF00 --change-name 1:EFI "$disk"
  refresh "$disk"

  mkfs.vfat -n EFI "$disk-part1"

  # Swap (partition 2) -- 4GB
  echo "Creating swap partition"
  sgdisk --new 2:0:+$swap_size --typecode 2:8200 --change-name 2:swap "$disk"
  refresh "$disk"

  mkswap -L swap "$disk-part2"
  swapon "$disk-part2"

  # Main pool (partition 3) -- remaining
  echo "Creating main pool partition"
  sgdisk --new 3:0:0 --typecode 3:8300 --change-name 3:pool "$disk"
  refresh "$disk"

  echo "Creating BIOS partition"
  sgdisk -a1 --new -n4:24K:+1000K --typecode 4:EF02 "$disk"
  refresh "$disk"

done

##############################
##### ZFS Pool Formating #####
##############################

# Create pool
echo "Creating main pool"
printf '%s\n' "$password" | zpool create \
  -O compression=zstd \
  -O encryption=aes-256-gcm \
  -O keylocation=prompt \
  -O keyformat=passphrase \
  -O dnodesize=auto \
  -o ashift=12 \
  -o autotrim=on \
  -O acltype=posixacl \
  -O canmount=off \
  -O normalization=formD \
  -O atime=off \
  -O xattr=sa \
  -R /mnt \
  pool \
  $vdev_type \
  "${disks[@]/%/-part3}"

# System datasets
zfs create -o canmount=off -o mountpoint=none -o refreservation=1G pool/reserved
zfs create -o canmount=off -o mountpoint=none pool/nixos
zfs create -o canmount=noauto -o mountpoint=/ pool/nixos/root
zfs create -o canmount=off -o mountpoint=/home pool/home
zfs create -o mountpoint=/root pool/home/root
#zfs create -o mountpoint=/var/lib/containerd/io.containerd.snapshotter.v1.zfs pool/containerd

# Home datasets
for user in "${users[@]}"; do
  zfs create "pool/home/$user"
done

# Initial snapshots
zfs snapshot -r pool@empty

# Mount
echo "Mounting"

zfs mount pool/nixos/root

for user in "${users[@]}"; do
  mkdir -p "/mnt/home/$user"
  #chown "$user:users" "/mnt/home/$user"
done

i=0
for disk in ${disks[@]}; do
  i=$((i+1))
  mount -o X-mount.mkdir "${disk/%/-part1}" "/mnt/boot/efi$i"
done

bash ./install.sh
