{
  pkgs,
  lib,
  ...
}:
with lib; {
  # Mount special filesystems before services
  systemd.services.containerd.requires = ["var-lib-containerd-io.containerd.snapshotter.v1.overlayfs.mount"];
  systemd.services.docker.requires = ["var-lib-docker-overlay2.mount"];

  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;
}
