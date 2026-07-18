{
  config,
  pkgs,
  lib,
  ...
}:
# Clean with:
# sudo rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /etc/kube-flannel/ /var/lib/cni/ /etc/kubernetes/ /var/lib/containerd/ /etc/cni/ /run/containerd/ /run/flannel/ /run/kubernetes/
with lib; let
  masterHostname = config.networking.hostName;
  masterAddress = "10.0.0.1";
  masterPort = 6443;
  adminUser = "david";
in {
  environment.systemPackages = with pkgs; [
    # Basic kubernetes CLIs
    kubectl

    # SOPS
    sops

    # Gitops CLI
    argocd

    # Containerd command line tools (e.g., crictl)
    cri-tools
  ];

  environment.sessionVariables = {
    CONTAINER_RUNTIME_ENDPOINT = "unix:///run/containerd/containerd.sock";
  };

  # Wait until pass-though container proxy is running
  #systemd.services.containerd = {
  #  requires = ["nexus.service"];
  #  after = ["nexus.service"];
  #};

  # Copy the cluster admin kubeconfig to the admin users's home if it doesn't already exist
  system.activationScripts = {
    giveUserKubectlAdminAccess = ''
      # Link to admin kubeconfig
      install -D -m 600 "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}" "/root/.kube/config"

      if [ ! -f "/home/${adminUser}/.kube/config" ]; then
        install -d -o "${adminUser}" -g users "/home/${adminUser}/.kube/"
        install -o "${adminUser}" -g users -m 600 "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}" "/home/${adminUser}/.kube/config"
      fi
    '';
  };

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = masterHostname;

    package = pkgs.unstable.kubernetes;

    # See justfile for instructions to refresh the self-signed cert
    easyCerts = true;

    # Use `hostname.cluster` instead of `cluster.local` since Android can't resolve .local through a VPN
    addons.dns.clusterDomain = "${masterHostname}.cluster";

    # Documentation: https://coredns.io/plugins/
    addons.dns.corefile = ''
      .:10053 {
        # Log errors
        errors

        # Support a /health endpoint
        health :10054

        # Support a /metrics endpoint
        prometheus :10055

        # Resolve k8s pods
        kubernetes ${config.services.kubernetes.addons.dns.clusterDomain} {
          pods insecure
        }

        forward . 9.9.9.9 {
          # Don't forward tailscale or cluster addresses
          except ts.net ${config.services.kubernetes.addons.dns.clusterDomain}
        }

        # Cache
        cache 30

        # Break loops
        loop

        # Reload when the config changes
        reload

        # Round-robin
        loadbalance
      }
    '';

    path = [
      config.services.openiscsi.package
    ];

    # Allow swap on host machine
    # Don't inherit DNS from host
    # Override default pod capacity (110)
    kubelet.extraOpts = "--fail-swap-on=false --resolv-conf= --max-pods=150";

    # Gracefully terminate pods on reboot/shutdown so they don't linger as `Unknown`
    # (NodeLost) ghosts and so devices (frigate/home-assistant/immich) are released
    # cleanly. These are KubeletConfiguration fields (no CLI flag exists); merged into
    # the generated --config file by the nixpkgs kubelet module. Requires
    # services.logind InhibitDelayMaxSec >= shutdownGracePeriod (set below).
    kubelet.extraConfig = {
      shutdownGracePeriod = "60s"; # total budget to drain pods on shutdown
      shutdownGracePeriodCriticalPods = "15s"; # subset reserved for critical pods (< total)

      # Tighter rotation than the 10Mi/5 defaults so per-container worst case is
      # 15Mi, keeping total usage well inside the /var/log/pods tmpfs below
      containerLogMaxSize = "5Mi";
      containerLogMaxFiles = 3;
    };

    # Allow privileged containers
    apiserver.extraOpts = "--allow-privileged";
  };

  # TODO: get in-cluster API access working without this
  # It neems like I need a router for this to work?
  # e.g. `curl --insecure 'https://10.0.0.1:443/api/v1/namespaces'
  networking.firewall.allowedTCPPorts = [
    masterPort

    # Monitoring ports
    9100 # Node exporter
    10250 # Kubelet

    # Home assistant
    8123

    # Victoria Metrics
    8428

    # Matter
    5540
    5580
    8482
    7586
    7587
  ];

  # Keep container logs in RAM: they're a constant stream of small appends that
  # churn the root dataset (txg commits + snapshot growth) for ~100Mi of data.
  # Logs don't survive a reboot; `kubectl logs` is unaffected. Cluster-wide usage
  # stays far below this cap because of the rotation limits set above.
  fileSystems."/var/log/pods" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["size=2G" "mode=0755" "nosuid" "nodev" "noexec"];
  };

  boot.kernel.sysctl = {
    # Defaults to 128 and causes 'too many open files' error for pods
    "fs.inotify.max_user_instances" = 1024;

    # Defaults to 120 and causes thread devices to drop off
    # https://github.com/matter-js/matterjs-server/blob/main/docs/os_requirements.md#stateful-firewalls-host-vm-hypervisor
    "net.netfilter.nf_conntrack_udp_timeout_stream" = 1800;
  };

  # Give the kubelet's shutdown inhibitor enough time to drain pods before logind
  # proceeds with shutdown. Must be >= the kubelet shutdownGracePeriod set above.
  services.logind.settings.Login.InhibitDelayMaxSec = 90;

  # Set the proper dependency, otherwise it fails to connect on shutdown and doesn't shutdown quickly
  systemd.services.kube-apiserver.unitConfig = {
    Wants = ["etcd.service"];
    After = ["etcd.service"];
  };

  # Override the cfssl default signing profile to issue long-lived certs (10y instead of 720h/30d).
  # The upstream pki.nix bakes the cfssl server's own TLS cert at the 30d default and does NOT add
  # it to certmgr's renewal list, so once it expires the whole renewal chain breaks (no one can
  # talk to cfssl) and you must wipe /var/lib/cfssl to recover. Long-lived certs sidestep this.
  #  - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/cluster/kubernetes/pki.nix
  services.cfssl.configFile = mkForce (toString (pkgs.writeText "cfssl-config.json" (builtins.toJSON {
    signing.profiles.default = {
      usages = ["digital signature"];
      auth_key = "default";
      expiry = "87600h";
    };
    auth_keys.default = {
      type = "standard";
      key = "file:${config.services.cfssl.dataDir}/apitoken.secret";
    };
  })));

  # Remove `hosts` config from cert requests, since they are often invalid DNS names. This causes
  # certmgr to renew certs and restart every 30m, which bounces the connection to the apiserver:
  #  - https://github.com/NixOS/nixpkgs/blob/6c5e707c6b5339359a9a9e215c5e66d6d802fd7a/nixos/modules/services/cluster/kubernetes/pki.nix#L254
  #  - journalctl -u certmgr --since -1h | rg 'needs refresh' | rg -o '[^ ]*.json' | sort | uniq
  services.certmgr.specs =
    (builtins.listToAttrs (builtins.map (name: {
        inherit name;
        value = {request.hosts = [];};
      }) [
        "addonManager"
        "apiserverKubeletClient"
        "controllerManagerClient"
        "kubeletClient"
        "kubeProxyClient"
        "schedulerClient"
        "serviceAccount"
      ]))
    // {
      # Grant admins access to cluster key
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/cluster/kubernetes/default.nix
      clusterAdmin.private_key = {
        group = "wheel";
        mode = "0640";
      };
    };
}
