{ pkgs, ... }:

{
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

  # Fix random hangs
  # https://nixos.wiki/wiki/Bootloader#Installing_x86_64_NixOS_on_IA-32_UEFI
  # https://forum.porteus.org/viewtopic.php?t=8432
  boot.kernelParams = [
    "pnpbios=off"
    "noacpi"
    "intel_idle.max_cstate=1"
    "delay=5"
    "i915.fastboot=0"
    "intel_pstate=passive"
  ];
}
