{
  pkgs,
  lib,
  ...
}:
with lib; {
  # Must use at least 6.2 for Intel GPU support
  # Must use a package compatabile with ZFS
  boot.kernelPackages = pkgs.kernel.linuxKernel.packages.linux_6_3;
}
