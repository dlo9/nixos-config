{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib; let
  # Put the file in the store, so that the derivation doesn't change every time.
  # Otherwise, the file path changes each time anything in the repo changes,
  # delaying build times
  # TODO: only change if it ends in `-source`?
  store = f: builtins.toFile "contents" (builtins.readFile f);

  # TODO: this is duplicated
  hostYamlPath = host: "${inputs.self}/hosts/${host}/secrets.yaml";
  hostYaml = host: store (hostYamlPath host);
  hostYamlExists = host: pathExists (hostYamlPath host);

  importSecrets = sopsFile: let
    attrToSecrets = mapAttrs' (
      name: value: {
        inherit name;

        value =
          (value.sopsNix or {})
          // {
            inherit sopsFile;
            key = "${name}/contents";
          };
      }
    );

    isEnabled = name: value:
      (value.enable or false)
      && (value ? contents);

    contents = pkgs.dlo9.lib.fromYAML sopsFile;
    enabledContents = filterAttrs isEnabled contents;
  in
    attrToSecrets enabledContents;
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = mkDefault "${inputs.self}/hosts/${hostname}/secrets.yaml";
    gnupg.sshKeyPaths = mkDefault []; # Disable automatic SSH key import

    age = {
      # This file must be in the filesystems mounted within the initfs.
      # I put it in the root filesystem since that's mounted first.
      keyFile = mkDefault "${config.xdg.configHome}/sops-age-keys.txt";
      sshKeyPaths = mkDefault []; # Disable automatic SSH key import
    };

    # Set secrets for the current host
    secrets = optionalAttrs (hostYamlExists hostname) (importSecrets (hostYaml hostname));
  };
}
