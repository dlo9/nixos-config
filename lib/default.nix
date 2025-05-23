{
  callPackage,
  lib,
  formats,
  inputs,
}: rec {
  fromYAML = callPackage ./fromYAML.nix {};
  fromYAMLString = callPackage ./fromYAMLString.nix {};
  jsonTrace = value: builtins.trace (builtins.toJSON value) value;

  ext = path: lib.last (lib.splitString "." path);

  # AttrSet of extention to convertion function
  # https://github.com/NixOS/nixpkgs/blob/f78a20aa5cdb449134d5a0fa03fe82b804353fbb/pkgs/pkgs-lib/formats.nix
  serdes = rec {
    toml = (formats.toml {}).generate;
    yaml = (formats.yaml {}).generate;
    yml = yaml;
    ini = (formats.ini {}).generate;
  };

  # Returns a convertion function for the given path
  serdeFromFilename = path: serdes."${ext path}" path;

  xdgFiles = lib.mapAttrs (path: value: {source = serdeFromFilename path value;});

  # Ensures the store path of a file is based only on the file's contents. Otherwise,
  # paths often contain the hash fo the entire flake, resulting in frequent,
  # unnecessary rebuilds
  #
  # TODO: only change if it starts with `/nix/store/<hash>-source/`?
  store = f: builtins.toFile "contents" (builtins.readFile f);

  storeIfExists = f: lib.optionalString (lib.pathExists f) (store f);

  secrets = rec {
    # Returns the store path to a hosts's secrets file, or the empty string if
    # the file does not exist
    hostSops = host: storeIfExists "${inputs.self}/hosts/${host}/secrets.yaml";

    # Returns all hostnames
    hosts = lib.attrNames (
      lib.filterAttrs
      (name: value: value == "directory")
      (builtins.readDir "${inputs.self}/hosts")
    );

    # Parses a sops file
    parseSops = f: lib.optionalAttrs (f != "") (fromYAML f);

    # Returns exports from a sops file
    sopsExports = sopsFile: let
      attrToExports = lib.mapAttrs' (
        name: value: {
          inherit name;
          value = value.exports;
        }
      );

      # Return true if the secret is enabled and has exports
      isEnabled = name: value:
        (value.enable or false)
        && (builtins.isAttrs (value.exports or ""));

      enabledContents = lib.filterAttrs isEnabled (parseSops sopsFile);
    in
      attrToExports enabledContents;

    # Returns secrets from a sops file
    sopsSecrets = sopsFile: let
      attrToSecrets = lib.mapAttrs' (
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

      # Return true if the secret is enabled and is non-empty
      isEnabled = name: value:
        (value.enable or true)
        && (value ? contents);

      enabledContents = lib.filterAttrs isEnabled (parseSops sopsFile);
    in
      attrToSecrets enabledContents;

    # Return the secrets for a given host
    hostSecrets = hostname: sopsSecrets (hostSops hostname);

    # Return secret exports for all hosts
    hostExports = lib.genAttrs hosts (hostname: sopsExports (hostSops hostname));
  };

  maintainers.dlo9 = {
    email = "if_coding@fastmail.com";
    github = "dlo9";
    githubId = 7187117;
    name = "David Orchard";
  };
}
