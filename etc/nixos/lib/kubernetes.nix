{ config, pkgs, ... }:
let
  kubeMasterHostname = "pavil";
  kubeMasterAPIServerPort = 6443;
in
{
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
	    user=david
		  mkdir -p /home/$user/.kube
	    ln -sf /etc/kubernetes/cluster-admin.kubeconfig /home/$user/.kube/config

		  # Grant access to cluster key
		  chown root:wheel /var/lib/kubernetes/secrets/cluster-admin-key.pem
		  chmod 660 /var/lib/kubernetes/secrets/cluster-admin-key.pem
	  '';
  };

  services.kubernetes = {
    roles = ["master" "node"];
	  kubelet.clusterDomain = "cluster" + kubeMasterHostname;
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      #advertiseAddress = kubeMasterIP;
    };

    # use coredns
    addons.dns.enable = true;

    # needed if you use swap
    kubelet.extraOpts = "--fail-swap-on=false";
  };

  #virtualisation.cri-o.pauseImage = "k8s.gcr.io/pause:3.6";

  # Enable nvidia support
  #services.kubernetes.kubelet.containerRuntime = "docker";
  hardware.opengl.driSupport32Bit = true;
  virtualisation.docker = {
    enable = true;

    # use nvidia as the default runtime
    #enableNvidia = true;
    #extraOptions = "--default-runtime=nvidia";
    extraOptions = "--exec-opt native.cgroupdriver=systemd";
  };
}
