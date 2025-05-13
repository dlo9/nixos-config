{
  config,
  pkgs,
  lib,
  ...
}: {
  # dbus: Could not request service name: org.freedesktop.DBus.Error.AccessDenied Connection ":1.5" is not allowed to own the service "fi.w1.wpa_supplicant1" due to security policies in the configuration file
  # networking.wireless.dbusControlled = false;

  # https://discourse.nixos.org/t/wireless-connection-within-initrd/38317/13
  boot.initrd = let
    # TODO: Can I get rid of this?
    interface = "wlp2s0";
  in {
    # Must load network module on boot for SSH access
    # nix shell nixpkgs#pciutils -c lspci -v | grep -iA8 'network\|ethernet'
    availableKernelModules = [
      # See the wiki link above, ay not be necessary
      "ccm"
      "ctr"
      "iwlmvm"

      "r8169" # Ethernet
      "iwlwifi" # wifi
    ];

    systemd = {
      # enable = true;
      # dbus.enable = true;

      # packages = [pkgs.wpa_supplicant];
      initrdBin = [
        pkgs.wpa_supplicant
      ];
      # targets.initrd.wants = ["wpa_supplicant@${interface}.service"];
      targets.initrd.wants = ["wpa_supplicant.service"];
      storePaths = [
        config.systemd.services.wpa_supplicant.script
      ];

      # prevent WPA supplicant from requiring `sysinit.target`.
      # services.wpa_supplicant = config.systemd.services.wpa_supplicant;
      # services.wpa_supplicant = config.systemd.services.wpa_supplicant;

      # services.wpa_supplicant = lib.recursiveUpdate (lib.removeAttrs config.systemd.services.wpa_supplicant ["confinement" "reloadIfChanged" "reloadTriggers" "restartIfChanged" "restartTriggers" "runner" "startAt" "stopIfChanged" "startLimitIntervalSec"]) {
      #   unitConfig.DefaultDependencies = false;
      # };

      services.wpa_supplicant = lib.filterAttrs (n: v:
        builtins.elem n [
          "serviceConfig"
          "path"
          "script"
          "after"
          "description"
          "before"
          "wants"
          "requires"
          "wantedBy"
        ])
      config.systemd.services.wpa_supplicant;

      # services.wpa_supplicant.unitConfig.DefaultDependencies = false;
      # services."wpa_supplicant@".unitConfig.DefaultDependencies = false;

      # users.root.shell = "/bin/systemd-tty-ask-password-agent";

      # network.enable = true;
      # network.networks."10-wlan" = {
      #   matchConfig.Name = interface;
      #   networkConfig.DHCP = "yes";
      # };
    };

    # Copy the sops secret from the running system.
    # I haven't tested this, but presumedly this will fail on a new system since the secret hasn't been decrypted yet.
    secrets."${config.sops.secrets.wireless-env.path}" = config.sops.secrets.wireless-env.path;

    # network.enable = true;
    # network.ssh = {
    #   enable = true;
    #   port = 22;
    #   hostKeys = ["/etc/ssh/ssh_host_ed25519_key"];
    #   authorizedKeys = default.user.openssh.authorizedKeys.keys;
    # };
  };
}
