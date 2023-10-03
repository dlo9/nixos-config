{
  pkgs,
  lib,
  ...
}:
with lib; {
  # Must use at least 6.2 for Intel GPU support
  # Must use a package compatabile with ZFS
  boot.kernelPackages = pkgs.kernel.linuxKernel.packages.linux_6_3;

  # Mount special filesystems before services
  systemd.services.containerd.requires = ["var-lib-containerd-io.containerd.snapshotter.v1.overlayfs.mount"];
  systemd.services.docker.requires = ["var-lib-docker-overlay2.mount"];
}
