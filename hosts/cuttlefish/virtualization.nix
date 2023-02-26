{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  sysCfg = config.sys;
in
{
  config = {
    # Virtualization
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [
      virt-manager
    ];

    users.users."${sysCfg.user}".extraGroups = [ "libvirtd" ];
  };
}
