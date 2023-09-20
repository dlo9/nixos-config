{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  xdg.configFile."wrap.yaml".source = ./wrap.yaml;

  home.packages = with pkgs; [
    kubectl

    # gcloud components install gke-gcloud-auth-plugin
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]))

    # Use a new launcher since spotlight doesn't find nix GUI applications:
    # https://github.com/nix-community/home-manager/issues/1341
    raycast

    # Java tools
    visualvm
    jetbrains.idea-ultimate
    gradle
    groovy
    google-java-format
    maven

    # Golang
    go
    protobuf

    # Kafka
    kcat
    kafkactl

    # Python
    # python38
    # python39
    # python310Full
    # python311
    # python312

    # Shell tools
    gnused
    coreutils-prefixed
    gawk

    # Bazel
    bazelisk
    bazel-buildtools

    # Other tools
    ansible
    mongosh
    openldap
    terraform

    # SQL Server
    # unixODBC
    # unixODBCDrivers.msodbcsql17

    # Window manager/hotkeys
    skhd

    # Business apps
    slack
    zoom-us
    teams
  ];

  home.sessionVariables = rec {
    # Java versions
    JAVA_HOME_8 = pkgs.jdk8;
    JAVA_HOME_11 = pkgs.jdk11;
    JAVA_HOME_17 = pkgs.jdk17;
    JAVA_HOME_19 = pkgs.jdk19;

    # HOMEBREW_CURLRC = "1";
    RUST_BACKTRACE = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
  };

  home.sessionPath = [
    "/Users/dorchard/.wrap/shims"
    "/Users/dorchard/.local/bin"
    "/Users/dorchard/code/dorchard/adhoc/bin"
    "/Users/dorchard/.cargo/bin"
    "/Users/dorchard/.jenv/bin"
    "/Users/dorchard/go/bin"
    "/opt/homebrew/bin"
  ];

  programs.fish.interactiveShellInit = ''
    # Jenv rehash is really slow -- exclude it from the init process
    # so that new tmux windows don't take 1s+ to create
    jenv init - fish | command grep -Ev 'jenv rehash|refresh-plugins' | source | eval &
  '';

  programs.fish.functions = {
    convert-logs-timestamp = ''
      jq '.ts |= (. | tostring [0:10] | tonumber | localtime | strftime("%Y-%m-%dT%H:%M:%S%z"))' $argv
    '';

    get-random = ''
      while true
        uuidgen | tr -d '\n' | pbcopy
        sleep 0.2
      end
    '';

    unfix = ''
      tr '\001\002' '|?' $argv
    '';
  };

  programs.ssh = {
    enable = true;
    matchBlocks."d1lrtcappprd?".extraOptions = {
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  home.activation = {
    setWallpaper = ''
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.wallpapers.default}"'
    '';

    setupJenv = ''
      PATH="$PATH:/opt/homebrew/bin"

      # The export plugin needs to be run to auto-export $JAVA_HOME.
      jenv sh-enable-plugin export >/dev/null

      jenv add ${pkgs.jdk8}
      jenv add ${pkgs.jdk11}
      jenv add ${pkgs.jdk17}
      jenv add ${pkgs.jdk19}
      jenv global 19

      jenv rehash
    '';
  };

  home.file = {
    # Silence "last login" text when a new terminal is opened
    ".hushlogin".text = "";
  };

  home.shellAliases = let
    team = "trade-processing";
    gitops = "~/code/gitops";
    app = "${gitops}/deploy/app";
    afsapi = "${gitops}/deploy/afsapi";
    infra = "~/code/apexinternal-gitops/kubernetes/infra/team/trade-processing/overlays";

    env-dirs = env: {
      "${env}" = "pushd ${app}/${env}/${team}";
      "${env}-afs" = "pushd ${afsapi}/${env}/${team}";
      "${env}-infra" = "pushd ${infra}/${env}/releases";
    };
  in
    {
      gitops = "pushd ${gitops}";

      mono = "pushd ~/code/source";
      tp = "pushd ~/code/trade-processing";

      braggart = "pushd ~/code/braggart";
      hero = "pushd ~/code/herodotus";
      hippo = "pushd ~/code/hippocrates";

      rtce = "pushd ~/code/rtce";
      rtceprod = "pushd ~/code/rtceprod/servers/Gateways/Customer/FBI";

      adhoc = "pushd ~/code/dorchard/adhoc";
      queries = "pushd ~/code/dorchard/adhoc/queries";
      g = "pushd ~/g";
    }
    // (env-dirs "dev")
    // (env-dirs "stg")
    // (env-dirs "uat")
    // (env-dirs "prd");
}
