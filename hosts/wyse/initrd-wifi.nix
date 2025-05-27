{
  config,
  pkgs,
  lib,
  ...
}: {
  # https://discourse.nixos.org/t/wireless-connection-within-initrd/38317/13
  boot.initrd = {
    # Must load network module on boot for SSH access
    # nix shell nixpkgs#pciutils -c lspci -v | grep -iA8 'network\|ethernet'
    availableKernelModules = [
      # Ethernet
      "r8169"

      # Wifi
      "iwlwifi"
      "iwlmvm" # This isn't marked by lspci, but is necessary
      "ccm" # Necessary for wireless encryption
    ];

    systemd = let
      # Get the config file
      # We can to use writeStringReferencesToFile instead of manually parsing or else nix complains
      # about accessing absolute paths during pure evaluation
      oldWirelessConfig = builtins.head (lib.splitString "\n" (lib.readFile (pkgs.writeStringReferencesToFile config.systemd.services.wpa_supplicant.script)));

      # Wheel doesn't exist in initrd
      newWirelessConfig = builtins.toFile "wpa_supplicant.conf" (builtins.replaceStrings ["ctrl_interface_group=wheel"] [""] (builtins.readFile oldWirelessConfig));
    in {
      initrdBin = with pkgs; [
        # Uncomment to debug
        #iproute2
      ];

      # Dependencies aren't tracked properly:
      # https://github.com/NixOS/nixpkgs/issues/309316
      storePaths =
        config.boot.initrd.systemd.services.wpa_supplicant.path
        ++ (lib.splitString "\n" (lib.readFile (pkgs.writeStringReferencesToFile config.boot.initrd.systemd.services.wpa_supplicant.script)));

      services.wpa_supplicant = {
        wantedBy = ["initrd.target"];
        path = config.systemd.services.wpa_supplicant.path;

        # Replace the old config with our new one
        # Remove some startup args
        script = builtins.replaceStrings [oldWirelessConfig "-s -u "] [newWirelessConfig ""] config.systemd.services.wpa_supplicant.script;
      };
    };

    # Copy the sops secret from the running system.
    # I haven't tested this, but presumedly this will fail on a new system since the secret hasn't been decrypted yet.
    secrets."${config.sops.secrets.wireless-env.path}" = config.sops.secrets.wireless-env.path;
  };
}
