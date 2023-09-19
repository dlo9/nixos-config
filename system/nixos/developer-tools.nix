{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    # TODO: probably not necessary, should remove
    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    # Docker
    virtualisation.docker = {
      enable = mkDefault true;
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
        ovmf = {
          enable = mkDefault true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = mkDefault true;
              tpmSupport = mkDefault true;
              csmSupport = mkDefault true;
            })
            .fd
          ];
        };
      };
    };
  };
}
