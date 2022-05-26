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
    # packages for administration tasks
    environment.systemPackages = with pkgs; [
      kompose
      kubectl
      kubernetes
    ];

    # services.kubernetes.dataDir = "/var/lib/kubernetes";

    system.activationScripts = {
      giveUserKubectlAdminAccess = ''
        # Link to admin kubeconfig
        mkdir -p "/home/${cfg.admin}/.kube"
        ln -sf "/etc/kubernetes/cluster-admin.kubeconfig" "/home/${cfg.admin}/.kube/config"

        # Grant access to cluster key
        chown root:wheel "/var/lib/kubernetes/secrets/cluster-admin-key.pem"
        chmod 660 "/var/lib/kubernetes/secrets/cluster-admin-key.pem"
      '';
    };

    services.kubernetes = {
      roles = [ "master" "node" ];
      masterAddress = cfg.masterHostname;
      #masterAddress = "10.1.0.1";

      # TODO: CoreDNS uses wrong IP for some reason
      addons.dns.enable = false;

      kubelet.extraOpts = "--fail-swap-on=false";
    };

    # Is this the magic right here?
    #networking.firewall.enable = false;

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