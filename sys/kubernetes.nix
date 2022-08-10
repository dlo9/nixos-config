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
      # Basic kubernetes CLIs
      kubectl
      kustomize

      # Helm
      kubernetes-helm

      # SOPS
      sops

      # SOPS kustomize plugin
      # https://github.com/NixOS/nixpkgs/issues/175515
      (pkgs.kustomize-sops.overrideAttrs (oldAttrs: {
        installPhase = ''
          mkdir -p $out/lib/viaduct.ai/v1/ksops/
          mv $GOPATH/bin/kustomize-sops $out/lib/viaduct.ai/v1/ksops/ksops
        '';
      }))

      # Gitops CLI
      argocd

      # Containerd command line tools (e.g., crictl)
      cri-tools
    ];

    environment.sessionVariables = {
      KUSTOMIZE_PLUGIN_HOME = "/run/current-system/sw/lib";
      CONTAINER_RUNTIME_ENDPOINT = "unix:///run/containerd/containerd.sock";
    };

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
      easyCerts = true;

      # Use `hostname.cluster` instead of `cluster.local` since Android can't resolve .local through a VPN
      addons.dns.clusterDomain = "${cfg.masterHostname}.cluster";

      path = [
        config.services.openiscsi.package
      ];

      # Allow swap on host machine
      kubelet.extraOpts = "--fail-swap-on=false";

      # Allow privileged containers
      apiserver.extraOpts = "--allow-privileged";
    };

    # ISCSI services required for OpenEBS (PVC storage):
    # https://openebs.io/docs/user-guides/prerequisites#linux-platforms
    services.openiscsi = {
      enable = true;
      name = config.networking.hostName;
    };

    # TODO: get in-cluster API access working without this
    # It neems like I need a router for this to work?
    # e.g. `curl --insecure 'https://10.0.0.1:443/api/v1/namespaces'
    networking.firewall.allowedTCPPorts = [
      cfg.masterPort

      # Monitoring ports
      9100 # Node exporter
      10250 # Kubelet

      # Home assistant
      8123
    ];

    boot.kernel.sysctl = {
      # Defaults to 128 and causes 'too many open files' error for pods
      "fs.inotify.max_user_instances" = 1024;
    };

    # To see available snapshotters, run: `ctr plugins ls | grep io.containerd.snapshotter`
    #   - zfs: slow, clutters filesystem
    #   - overlayfs: doesn't work on zfs, so /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs MUST be a non-zfs mount (e.g., ext4 zvol)
    virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".containerd.snapshotter = "overlayfs";
  };
}
