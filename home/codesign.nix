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
}:
lib.mkIf (config.codesign.packages != [] || config.codesign.bundles != []) {
  # After copyApps so the bundles exist; runs as the user, so it can write
  # ~/.cache and read the user-owned /run/secrets/codesign-key.
  home.activation.codesign = lib.hm.dag.entryAfter ["copyApps"] (
    mylib.codesign.mkSignScript {
      specs = map (p: p.passthru.codesignSpec) config.codesign.packages;
      bundles = config.codesign.bundles;
      rcodesign = pkgs.rcodesign;
    }
  );
}
