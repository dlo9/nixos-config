{ config, pkgs, lib, ... }:

# Clean with:
# sudo rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /etc/kube-flannel/ /etc/kubernetes/ /var/lib/containerd/ /etc/cni/ /run/containerd/ /run/flannel/ /run/kubernetes/

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.kubernetes;
in
{
  options.sys.kubernetes = with types; {
    enable = mkEnableOption "kubernetes" // { default = false; };

    masterHostname = mkOption {
      type = nonEmptyStr;
      default = config.networking.hostName;
      description = "Hostname for the master node";
    };

    masterAddress = mkOption {
      type = nonEmptyStr;
      default = "10.0.0.1";
      #default = "127.0.0.1";
      description = "Address for the master node";
    };

    masterPort = mkOption {
      type = ints.u16;
      default = 6443;
      description = "Port for the master node";
    };

    admin = mkOption {
      type = nonEmptyStr;
      default = sysCfg.user;
      description = "User to grant administrator access";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kubectl
      kustomize
      # https://github.com/NixOS/nixpkgs/issues/175515
      (pkgs.kustomize-sops.overrideAttrs (oldAttrs: {
        installPhase = ''
          mkdir -p $out/lib/viaduct.ai/v1/ksops/
          mv $GOPATH/bin/kustomize-sops $out/lib/viaduct.ai/v1/ksops/ksops
        '';
      }))
      kubernetes-helm
      sops
      argocd
    ];

    environment.sessionVariables = {
      KUSTOMIZE_PLUGIN_HOME = "/run/current-system/sw/lib";
    };

    # services.kubernetes.dataDir = "/var/lib/kubernetes";

    # Copy the cluster admin kubeconfig to the admin users's home if it doesn't already exist
    system.activationScripts = {
      giveUserKubectlAdminAccess = ''
        # Link to admin kubeconfig
        install -D -m 600 "/etc/kubernetes/cluster-admin.kubeconfig" "/root/.kube/config"

        if [ ! -f "/home/${cfg.admin}/.kube/config" ]; then
          install -d -o "${cfg.admin}" -g users "/home/${cfg.admin}/.kube/"
          install -o "${cfg.admin}" -g users -m 600 "/etc/kubernetes/cluster-admin.kubeconfig" "/home/${cfg.admin}/.kube/config"
        fi

        # Grant access to cluster key
        chown root:wheel "/var/lib/kubernetes/secrets/cluster-admin-key.pem"
        chmod 660 "/var/lib/kubernetes/secrets/cluster-admin-key.pem"
      '';
    };

    services.kubernetes = {
      roles = [ "master" "node" ];
      masterAddress = cfg.masterHostname;
      #masterAddress = "10.1.0.1";

      # Allow swap on host machine
      kubelet.extraOpts = "--fail-swap-on=false";

      # Allow privileged containers
      apiserver.extraOpts = "--allow-privileged";
    };

    # TODO: get in-cluster API access working without this
    # It neems like I need a router for this to work?
    # e.g. `curl --insecure 'https://10.0.0.1:443/api/v1/namespaces'
    networking.firewall.allowedTCPPorts = [
      cfg.masterPort

      # ArgoCD ports
      # Not sure why these are accessable?
      #31301
      #30681
    ];

    # networking.dhcpcd.denyInterfaces = [ "cuttlenet*" ];
    # services.kubernetes.kubelet.cni.config = [{
    #   name = "cuttlenet";
    #   type = "flannel";
    #   cniVersion = "0.3.1";
    #   delegate = {
    #     bridge = "cuttlenet";
    #     isDefaultGateway = true;
    #     hairpinMode = true;
    #   };
    # }];

    # services.flannel = {
    #   iface = "cuttlenet";
    # };

    # To see available snapshotters, run: `ctr plugins ls | grep io.containerd.snapshotter`
    #   - zfs: slow, clutters filesystem
    #   - overlayfs: doesn't work on zfs
    virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".containerd.snapshotter = "native";

    #networking.enableIPv6 = false;
    #networking.firewall.trustedInterfaces = [ "flannel.1" "mynet" "docker0" ];
    # services.kubernetes = {
    #   roles = [ "master" "node" ];
    #   #kubelet.clusterDomain = "cluster" + cfg.masterHostname;
    #   kubelet.clusterDomain = cfg.masterHostname;
    #   masterAddress = cfg.masterAddress;
    #   apiserverAddress = "https://${cfg.masterAddress}:${toString cfg.masterPort}";
    #   apiserver = {
    #     securePort = cfg.masterPort;
    #     advertiseAddress = cfg.masterAddress;
    #   };

    #   # Use coredns
    #   addons.dns.enable = true;

    #   # Allow swap
    #   kubelet.extraOpts = "--fail-swap-on=false";
    # };

    # # Enable nvidia support
    # #services.kubernetes.kubelet.containerRuntime = "docker";
    # hardware.opengl.driSupport32Bit = true;
    # virtualisation.docker = {
    #   enable = true;

    #   # use nvidia as the default runtime
    #   #enableNvidia = true;
    #   #extraOptions = "--default-runtime=nvidia";
    #   extraOptions = "--exec-opt native.cgroupdriver=systemd";
    # };
  };
}
