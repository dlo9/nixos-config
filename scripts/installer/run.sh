#!/usr/bin/env bash

drive_count=2
drives=()

# Create drives
for i in $(seq 1 $drive_count); do
	drive="drive$i.qcow2"
	drives+=(-drive "file=$drive,format=qcow2")

	if [ ! -f "$drive" ]; then
		qemu-img create -f qcow2 "$drive" 32G
	fi
done

# Boot
# passwd: a
sudo qemu-system-x86_64 \
	-m 4G \
	-nographic \
	--enable-kvm \
	-cpu host \
	-cdrom nix.iso \
	-bios /usr/share/ovmf/OVMF.fd \
	-nic user,hostfwd=tcp::2222-:22 \
	-boot order=d \
	"${drives[@]}"
