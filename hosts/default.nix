{
  lib,
  pkgs,
  ...
}:
with lib;
with types; let
  hosts = attrNames (filterAttrs (n: v: v == "directory") (readDir ./.));

  importExports = sopsFile: let
    fileToExports = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable ? false))
        then (value.exports ? {})
        else {}
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = fromYAML sopsFile;
  in
    removeNulls (fileToExports contents);

  importSecrets = sopsFile: let
    fileToSecrets = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable ? false))
        then {"${key}/contents" = value.attrs // {inherit sopsFile;};}
        else null
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = fromYAML sopsFile;
  in
    removeNulls (fileToSecrets contents);
in {
  imports = [
    ./hosts/${hostName}
  ];

  options = {
    hostExports = mkOption {
      description = "exported host configurations";
      # type = attrsOf (submodule (import ./host.nix));
      type = attrsOf anything;
    };
  };

  config = {
    networking.hostName = hostName;

    sops.secrets = builtins.listToAttrs (
      map (host: {
        name = host;
        value = importSecrets "./${host}/secrets.yaml";
      })
      hosts
    );

    hostExports = builtins.listToAttrs (
      map (host: {
        name = host;
        value = importExports "./${host}/secrets.yaml";
      })
      hosts
    );
  };
}
