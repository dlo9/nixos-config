{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./hardware.nix
    inputs.vscode-server.nixosModule
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  config = {
    # Qemu UEFI
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
              csmSupport = true;
            })
            .fd
          ];
        };
      };
    };

    boot.loader.grub.mirroredBoots = [
      {
        devices = ["nodev"];
        efiSysMountPoint = "/boot/efi";
        path = "/boot/efi/EFI";
      }
    ];

    boot.initrd.availableKernelModules = ["r8152"];

    # Bluetooth
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable A2DP Sink: https://nixos.wiki/wiki/Bluetooth
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };

    environment.systemPackages = with pkgs; [
      virt-manager

      # ADB fire tablet stuff
      gnome.zenity

      # Backups
      kopia

      (appimageTools.wrapType2 {
        name = "kopia-ui";
        src = fetchurl {
          url = "https://github.com/kopia/kopia/releases/download/v0.12.1/KopiaUI-0.12.1.AppImage";
          sha256 = "sha256-Kc7ylkXuvD+E6YRe52F1gJqoaAGwQkm/3D91q43P6gU=";
        };
      })
    ];

    # zrepl_switch to new bluetooth devices
    hardware.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [8888];
    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "stdout";
              level = "warn";
              format = "human";
              time = true;
              color = true;
            }
          ];
        };

        jobs = let
          # listToAttrs where the value is the same for all keys
          listToUnityAttrs = list: value: listToAttrs (forEach list (key: nameValuePair key value));

          # Order filesystems by retension time. If a filesystem is in two lists,
          # the shorter lifetime takes presidence:
          #   - no-repl: up to 1 day locally
          #   - short: up to 1 week remotely
          #   - medium: up to 1 month remotely
          #   - long: up to 1 year remotely

          retentionPolicies = {
            local = [
              "pool/home/david/.cache<"
              "pool/home/david/code<"
              "pool/nixos/nix<"
              "pool/games<"
              "pool/reserved<"
            ];

            short = ["pool/home/david/Downloads<"];

            medium = [];

            long = ["<"];
          };

          # Turns an attrSet of { filesystem -> bool } where each filesystem in the given
          # policy is set to `true`, and each filesystem in other policies is set to `false`
          getReplicationPolicy = policy: let
            myFs = retentionPolicies."${policy}";
            otherFs = flatten (mapAttrsToList (n: v: optionals (n != policy) v) retentionPolicies);
          in
            (listToUnityAttrs myFs true) // (listToUnityAttrs otherFs false);

          snapshotJob = retentionPolicy: rec {
            name = "snapshot ${retentionPolicy}-retention datasets";
            type = "snap";

            filesystems = getReplicationPolicy retentionPolicy;

            snapshotting = {
              type = "periodic";
              prefix = "zrepl_${retentionPolicy}_";
              interval = "15m";
            };

            pruning.keep = [
              # Keep local snapshots up to a week
              {
                type = "grid";
                grid = "1x1h(keep=all) | 23x1h | 6x1d";
                regex = "^zrepl_local_.*";
              }

              # Keep everything else, which will be pruned during replication
              {
                type = "regex";
                regex = "^zrepl_local_.*";
                negate = true;
              }
            ];
          };
        in [
          {
            name = "cuttlefish replication";
            type = "source";

            serve = {
              type = "tcp";
              listen = "100.111.108.84:8888";
              listen_freebind = true;
              clients = {
                "100.97.145.42" = "cuttlefish";
              };
            };

            # Only exclude filesystems which shouldn't replicate at all.
            # Otherwise, zrepl unnecessarily syncs the snapshots and then fails when deleting them
            filesystems = {"<" = true;} // listToUnityAttrs retentionPolicies.local false;

            send = {
              encrypted = true;
              large_blocks = true;
              compressed = true;
              embedded_data = true;
              raw = true;
            };

            snapshotting = {
              # Snapshots are done in separate jobs so that only one port is needed
              type = "manual";
            };
          }

          (snapshotJob "long")
          (snapshotJob "medium")
          (snapshotJob "short")
          (snapshotJob "local")
        ];
      };
    };
  };
}
