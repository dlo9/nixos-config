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

  home.stateVersion = "22.05";

  xdg.configFile."wrap.yaml".source = ./wrap.yaml;

  home.packages = with pkgs; [
    kubectl
    #tilt

    # gcloud components install gke-gcloud-auth-plugin
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]))

    # Use a new launcher since spotlight doesn't find nix GUI applications:
    # https://github.com/nix-community/home-manager/issues/1341
    raycast

    # Java tools
    visualvm
    #pkgs.master.jetbrains.idea-ultimate
    gradle
    groovy
    google-java-format
    maven
    #jd-gui # Decompiler

    # Golang
    go
    protobuf

    # Kafka
    kcat
    kafkactl
    apacheKafka

    # Python
    # python38
    # python39
    # python310Full
    # python311
    # python312
    pyenv

    # Shell tools
    gnused
    coreutils-prefixed
    gawk

    # Bazel
    bazelisk
    bazel-buildtools

    # Link bazel to bazelisk
    #(runCommand "my-bazel" {} ''mkdir -p $out/bin; ln -s ${bazelisk}/bin/bazelisk $out/bin/bazel'')
    (writeShellScriptBin "bazel" ''
      # Clear java home or else the default_system_javabase flag is set in from CLI but not from IntelliJ,
      # resulting in different startup opitons
      export JAVA_HOME=
      ${bazelisk}/bin/bazelisk "$@"
    '')

    # Other tools
    ansible
    mongosh
    openldap
    terraform
    flyway
    obsidian
    gh
    codeowners
    #postman
    jira-cli-go

    # SQL Server
    # unixODBC
    # unixODBCDrivers.msodbcsql17

    # Window manager/hotkeys
    skhd

    # Business apps
    #slack
    #zoom-us
    teams

    grpcurl
    ghz
  ];

  home.sessionVariables = rec {
    # Wipe path to prevent system binaries (e.g., vim) from coming before home-manager ones
    # https://github.com/nix-community/home-manager/issues/3324
    PATH = "";

    # Java versions
    JAVA_HOME_8 = pkgs.jdk8;
    JAVA_HOME_11 = pkgs.jdk11;
    JAVA_HOME_17 = pkgs.jdk17;
    JAVA_HOME_23 = pkgs.jdk23;

    # HOMEBREW_CURLRC = "1";
    RUST_BACKTRACE = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    JAVAX_NET_SSL_TRUSTSTORE = "/etc/ssl/certs/java/cacerts";
  };

  home.sessionPath = [
    "$HOME/code/dorchard/adhoc/bin"
    "$HOME/.jenv/bin"
    "$HOME/go/bin"
    "/opt/homebrew/bin"

    # Add nix paths
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/dorchard/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"

    # Re-add system paths (see home.sessionVariables)
    "/usr/local/bin"
    "/System/Cryptexes/App/usr/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
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

  programs.git.userEmail = "dorchard@apexfintechsolutions.com";

  programs.ssh = {
    enable = true;
    matchBlocks."d1lrtcapp*".extraOptions = {
      HostKeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedAlgorithms = "+ssh-rsa";
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/330735
  programs.vscode.package = mkForce pkgs.vscode;

  home.activation = {
    setWallpaper = ''
      osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.wallpapers.default}"'
    '';

    setupJenv = ''
      PATH="$PATH:/opt/homebrew/bin"

      # The export plugin needs to be run to auto-export $JAVA_HOME.
      jenv sh-enable-plugin export >/dev/null

      # Remove existing versions
      rm -rf "$(jenv root)/versions/"
      mkdir "$(jenv root)/versions/"

      jenv add ${pkgs.jdk8}
      jenv add ${pkgs.jdk11}
      jenv add ${pkgs.jdk17}
      jenv add ${pkgs.jdk23}
      jenv global 23

      jenv rehash
    '';

    # TODO: store ~/.config/gcloud/configurations/config_default instead?
    # setupGcloud = ''
    #   gcloud config set core/custom_ca_certs_file
    # '';
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

      rcn = (env-dirs "rcn").rcn-afs;
      sbx = (env-dirs "sbx").sbx-afs;
    }
    // (env-dirs "dev")
    // (env-dirs "stg")
    // (env-dirs "uat")
    // (env-dirs "prd");

  launchd.agents = {
    raycast = {
      enable = true;
      config = {
        KeepAlive = true;
        ProcessType = "Interactive";
        Program = "${pkgs.raycast}/Applications/Raycast.app/Contents/MacOS/Raycast";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/raycast/stderr";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/raycast/stdout";
      };
    };
  };
}
