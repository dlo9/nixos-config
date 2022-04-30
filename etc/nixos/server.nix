# TODO: https://www.reddit.com/r/NixOS/comments/6gh32h/suggestions_for_organizing_nixos_configs/
# Search for config options at: https://search.nixos.org/options?channel=21.11
{ config, pkgs, ... }:

{
  imports = [ ./system.nix ];

  boot.loader.grub.mirroredBoots = [
    { devices = ["nodev"]; path = "/boot/efi1"; }
  ];

  networking.interfaces.enp2s0.useDHCP = true;

  # GPU
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  ######################
  ##### ZFS CONFIG #####
  ######################

  # Should be random for each host to ensure pool doesn't replace root on a different host
  # tr -dc 0-9a-f < /dev/urandom | head -c 8
  networking.hostId = "7b10f945"; 

  # Must load network module on boot
  # lspci -v | grep -iA8 'network\|ethernet'
  boot.initrd.availableKernelModules = [ "r8169" ];
}

