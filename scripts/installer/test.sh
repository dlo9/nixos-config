#!/usr/bin/env bash

# Requirements (TODO: make this a flake):
#   - bash
#   - qemu, with OVMF (UEFI firmware)
#   - ssh
#   - 7z

# TODO:
#   - Start VM from ISO
#   - Edit install scripts with disk
#   - Run installer
#   - Move `qemu.nix` to flake

set -e
set -o pipefail

# Source libraries
source util.sh

state_dir="$HOME/.local/share/Trash/files/nix-installer-test"
disk_dir="$state_dir/disks"
boot_dir="$state_dir/boot"

installer_url="https://channels.nixos.org/nixos-22.05/latest-nixos-minimal-x86_64-linux.iso"
installer_iso="$boot_dir/nix-installer.iso"
initrd="initrd"
kernel="bzImage"

# Options
disk_count=2
disk_size=20G
vm_mem=4G
local_ssh_port=2222

# Create state directory
info "Storing test state at $state_dir"
info
mkdir -p "$state_dir" "$disk_dir" "$boot_dir"

# Create disks
disks=()
mkdir -p "$disk_dir"
for disk_num in $(seq "$disk_count"); do
    disk="$disk_dir/disk${disk_num}.qcow2"
    disks+=(-drive "file=$disk,format=qcow2")

    if [ -f "$disk" ]; then
        info "Disk #$disk_num already exists at $disk"
    else
        info "Creating disk #$disk_num with size $disk_size at $disk..."
        qemu-img create -f qcow2 "$disk" "$disk_size"
    fi
done
info

# Download iso
if [ -f "$installer_iso" ]; then
    info "Using Nix installer ISO at $installer_iso"
else
    info "Downloading Nix installer ISO from $installer_url to $installer_iso..."
    curl -L -o "$installer_iso" "$installer_url"
fi
info

# Extract boot files for custom kernel arguments
if [ ! -f "$boot_dir/$initrd" ] || [ ! -f "$boot_dir/$kernel" ]; then
    info "Extracting initrd and kernel to $boot_dir..."
    7z e "-o$boot_dir" "$installer_iso" "boot/$initrd" "boot/$kernel"
fi
info

# Find UEFI firmware file
info_ "Finding UEFI firmware... "
#bios="$(nix eval --raw -f '<nixpkgs>' OVMF.fd)/FV/OVMF.fd"
bios="$(ls /nix/store/*-OVMF-*-fd/FV/OVMF.fd | head -1)"
if [ -f "$bios" ]; then
    info "Using UEFI firmware from $bios"
else
    error "Not found"
    exit 1
fi
info

# Run it
info "Running VM. Use <Ctrl-a> + <c> + <q> to exit..."
export vm_mem installer_iso bios local_ssh_port extra_args="${disks[*]}"

rm -f test.log
expect -f test.exp
