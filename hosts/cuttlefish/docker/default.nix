{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  config = {
    # Can't use podman and k8s at the same time
    # https://github.com/NixOS/nixpkgs/issues/130804
    virtualisation.oci-containers.backend = "docker";
    # environment.etc."cni/net.d".enable = false;

    environment.systemPackages = [pkgs.dlo9.nss-docker];
    system.nssDatabases.hosts = ["docker"];
  };
}
