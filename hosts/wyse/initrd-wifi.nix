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
      # In 26.05 the wpa_supplicant service script references /etc paths
      # (/etc/wpa_supplicant/nixos.conf) rather than a /nix/store path, so we
      # render our own config from environment.etc and rewrite the script's
      # flags to point at it.
      # Drop ctrl_interface_group entirely — none of those groups exist in initrd
      newWirelessConfig = builtins.toFile "wpa_supplicant.conf" (
        lib.concatStringsSep "\n" (
          builtins.filter (line: !(lib.hasPrefix "ctrl_interface_group=" line))
          (lib.splitString "\n" config.environment.etc."wpa_supplicant/nixos.conf".text)
        )
      );
    in {
      initrdBin = with pkgs; [
        # Uncomment to debug
        #iproute2
      ];

      # Dependencies aren't tracked properly:
      # https://github.com/NixOS/nixpkgs/issues/309316
      storePaths =
        config.boot.initrd.systemd.services.wpa_supplicant.path
        ++ [newWirelessConfig];

      services.wpa_supplicant = {
        wantedBy = ["initrd.target"];
        path = config.systemd.services.wpa_supplicant.path;

        # Repoint the config flags at our store-resident copy, drop -s/-u
        script =
          builtins.replaceStrings
          [
            "-c /etc/wpa_supplicant/imperative.conf -I /etc/wpa_supplicant/nixos.conf"
            "-c /etc/wpa_supplicant/nixos.conf"
            "-s -u "
          ]
          [
            "-c ${newWirelessConfig}"
            "-c ${newWirelessConfig}"
            ""
          ]
          config.systemd.services.wpa_supplicant.script;
      };
    };

    # Copy the sops secret from the running system.
    # I haven't tested this, but presumedly this will fail on a new system since the secret hasn't been decrypted yet.
    secrets."${config.sops.secrets.wireless-env.path}" = config.sops.secrets.wireless-env.path;
  };
}
