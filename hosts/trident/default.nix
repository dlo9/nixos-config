{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./hardware
    ./services
  ];

  config = {
    # Change name of the default user
    users.users.david.name = "pi";
    home-manager.users.david = import ./home.nix;

    # pam_ssh_agent_auth.so fails to dlopen on aarch64 because __multf3
    # (libgcc soft-float for 128-bit long double) is undefined when the
    # Makefile links the .so with bare `ld`. Linking via `gcc` pulls
    # __multf3 from libgcc.a and embeds it locally.
    nixpkgs.overlays = [
      (final: prev: {
        pam_ssh_agent_auth = prev.pam_ssh_agent_auth.overrideAttrs (old: {
          makeFlags = (old.makeFlags or []) ++ ["LD=${prev.stdenv.cc.targetPrefix}gcc"];
        });
      })
    ];

    nix.distributedBuilds = true;
    services.davfs2.enable = false;
    services.fwupd.enable = false;
    fix-efi.enable = false;
    documentation.enable = false;
    documentation.man.enable = false;

    system.stateVersion = "24.11";
  };
}
