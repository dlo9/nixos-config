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
}
