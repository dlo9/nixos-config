# Darwin-only generic signer: on activation (like copyApps) it populates the
# user signing cache for each package in `codesign.packages` and re-signs each
# bundle in `codesign.bundles`. Both come from a host's codesign.nix — this
# module has no per-application knowledge.
{
  config,
  lib,
  pkgs,
  mylib,
  ...
}: {
  options.codesign = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Signed packages (mylib.codesign.signPackage results) whose bin/
        executables to populate in the user signing cache on activation
        (darwin only).
      '';
    };

    bundles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Absolute paths to .app bundles to re-sign with the stable codesign
        cert on activation (darwin only).
      '';
    };
  };

  config = lib.mkIf (config.codesign.packages != [] || config.codesign.bundles != []) {
    # After copyApps so the bundles exist; runs as the user, so it can write
    # ~/.cache and read the user-owned /run/secrets/codesign-key.
    home.activation.codesign = lib.hm.dag.entryAfter ["copyApps"] (
      mylib.codesign.mkSignScript {
        specs = map (p: p.passthru.codesignSpec) config.codesign.packages;
        bundles = config.codesign.bundles;
        rcodesign = pkgs.rcodesign;
      }
    );
  };
}
