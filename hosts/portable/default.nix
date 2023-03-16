{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
      development.enable = false;
      low-power = true;
      networking.authenticateTailscale = true;
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      efi.canTouchEfiVariables = false;
      grub.efiInstallAsRemovable = true;
      grub.useOSProber = false;

      grub.mirroredBoots = [
        #{ devices = [ "/dev/disk/by-id/usb-Lexar_USB_Flash_Drive_04PRY5BWVCGJ9U83-0:0" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
        { devices = [ "/dev/disk/by-id/usb-Leef_Supra_0171000000030148-0:0" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
      ];
    };

    hardware.cpu.intel.updateMicrocode = true;
    hardware.cpu.amd.updateMicrocode = true;

    boot.kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];

    # MINIX Neo Z83-4 Max uses a Broadcom wifi module which uses upstream firmware, but does not have the right name
    # (in `dmesg` look for `brcmfmac43455-sdio.MINIX-Z83-4.txt`)
    hardware.firmware = [
      (pkgs.callPackage
        ({ stdenv, linux-firmware }:

          stdenv.mkDerivation {
            pname = "minix-wireless-firmware";
            version = linux-firmware.version;

            phases = [ "installPhase" ];

            installPhase = ''
              runHook preInstall
              mkdir -p "$out/lib/firmware/brcm"

              cp "${linux-firmware}/lib/firmware/brcm/brcmfmac43455-sdio.MINIX-NEO Z83-4.txt" "$out/lib/firmware/brcm/brcmfmac43455-sdio.MINIX-Z83-4.txt"

              runHook postInstall
            '';
          })
        { }
      )
    ];

    # Ethernet modules for remote boot login
    boot.initrd.availableKernelModules = [
      "r8169" # Realtek ethernet
      "iwlwifi" # Intel wifi
    ];
  };
}
