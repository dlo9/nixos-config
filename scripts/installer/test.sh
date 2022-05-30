#!/usr/bin/env bash

# TODO:
#   - Create test dir
#   - Create two qcow2 files
#   - Download ISO?
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
installer_url="https://channels.nixos.org/nixos-21.11/latest-nixos-minimal-x86_64-linux.iso"
installer_iso="$state_dir/nix-installer.iso"

# Options
disk_count=2
disk_size=20G
vm_mem=4G
local_ssh_port=2222


# Create state directory
info "Storing test state at $state_dir"
info
mkdir -p "$state_dir"

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

# Find UEFI firmware file
info_ "Finding UEFI firmware... "
bios="$(nix eval --raw -f '<nixpkgs>' OVMF.fd)/FV/OVMF.fd"
if [ -f "$bios" ]; then
    info "$bios"
else
    error "Not found"
    exit 1
fi
info

# Run it
info "Running VM. Use <Ctrl-a> + <c> + <q> to exit..."
sudo qemu-system-x86_64 \
	-m "$vm_mem" \
	-nographic \
	--enable-kvm \
	-cpu host \
	-cdrom "$installer_iso" \
	-bios "$bios" \
	-nic "user,hostfwd=tcp::$local_ssh_port-:22" \
	-boot order=d \
	"${disks[@]}"
