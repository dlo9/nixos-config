{
  config,
  pkgs,
  lib,
  ...
}:
# Clean with:
# sudo rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /etc/kube-flannel/ /etc/kubernetes/ /var/lib/containerd/ /etc/cni/ /run/containerd/ /run/flannel/ /run/kubernetes/
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

  # Grant admins access to cluster key
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/cluster/kubernetes/default.nix
  services.certmgr.specs.clusterAdmin.private_key = {
    group = "wheel";
    mode = "0640";
  };

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = masterHostname;

    # Refresh kubernetes certificates with:
    # sudo rm -rf /var/lib/cfssl /var/lib/kubernetes/secrets && sudo systemctl restart cfssl; sleep 5; sudo systemctl restart certmgr; sleep 5; sudo systemctl restart kubernetes.slice; sleep 5; sudo chown david /var/lib/kubernetes/secrets/cluster-admin-key.pem
    easyCerts = true;

    # Use `hostname.cluster` instead of `cluster.local` since Android can't resolve .local through a VPN
    addons.dns.clusterDomain = "${masterHostname}.cluster";
    addons.dns.corefile = ''
      .:10053 {
        errors
        health :10054
        kubernetes ${config.services.kubernetes.addons.dns.clusterDomain} in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :10055
        # forward . /etc/resolv.conf
        forward . 192.168.1.1
        cache 30
        loop
        reload
        loadbalance
      }
    '';

    path = [
      config.services.openiscsi.package
    ];

    # Allow swap on host machine
    kubelet.extraOpts = "--fail-swap-on=false";

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

    # Matter
    5540
    8482
  ];

  boot.kernel.sysctl = {
    # Defaults to 128 and causes 'too many open files' error for pods
    "fs.inotify.max_user_instances" = 1024;
  };

  # Set the proper dependency, otherwise it fails to connect on shutdown and doesn't shutdown quickly
  systemd.services.kube-apiserver.unitConfig = {
    Wants = ["etcd.service"];
    After = ["etcd.service"];
  };
}
