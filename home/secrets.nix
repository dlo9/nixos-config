{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib; let
  # TODO: this is duplicated
  hostYaml = host: "${inputs.self}/hosts/${host}/secrets.yaml";
  hostYamlExists = host: pathExists (hostYaml host);

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
