{callPackage}: {
  fromYAML = callPackage ./fromYAML.nix {};
  fromYAMLString = callPackage ./fromYAMLString.nix {};
  jsonTrace = value: builtins.trace (builtins.toJSON value) value;

  maintainers.dlo9 = {
    email = "if_coding@fastmail.com";
    github = "dlo9";
    githubId = 7187117;
    name = "David Orchard";
  };
}
