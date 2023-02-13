{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./node-red.nix
  ];

  config = {
    # Can't use podman and k8s at the same time
    # https://github.com/NixOS/nixpkgs/issues/130804
    virtualisation.oci-containers.backend = "docker";
  };
}
