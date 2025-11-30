{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    # Docker
    virtualisation.docker = {
      enable = mkDefault (!config.virtualisation.podman.enable);
      enableOnBoot = mkDefault true;
    };

    virtualisation.podman = {
      enable = mkDefault false;
      dockerCompat = true;
      dockerSocket.enable = true;
    };

    programs = {
      adb.enable = mkDefault true;

      # Allow running unpatched binaries, including vscode-serer
      nix-ld.enable = mkDefault true;
    };

    # environment.systemPackages = with pkgs; [
    #   qemu_kvm
    #   OVMF
    #   libvirt
    # ];

    virtualisation.libvirtd = {
      enable = mkDefault true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = mkDefault true;
      };
    };
  };
}
