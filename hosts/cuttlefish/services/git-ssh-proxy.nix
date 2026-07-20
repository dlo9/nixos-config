{pkgs, ...}: {
  # Forgejo SSH ingress: forwards node port 2222 to traefik's git-ssh
  # entrypoint on the metallb-pinned LB IP.
  #
  # A traefik hostPort can't do this directly because the cluster's flannel
  # CNI setup doesn't chain the portmap plugin (confirmed via containerd
  # debug logs: no CNI-HOSTPORT-DNAT chain is ever created), so kubelet
  # silently ignores hostPort requests. This proxy is a lower-risk stopgap
  # that doesn't touch how pods get networking. Firewall port opened in
  # kubernetes.nix.
  systemd.sockets.git-ssh-proxy = {
    description = "Listen socket for Forgejo SSH proxy";
    wantedBy = ["sockets.target"];
    listenStreams = ["2222"];
  };

  systemd.services.git-ssh-proxy = {
    description = "Proxy Forgejo SSH to traefik git-ssh entrypoint";
    requires = ["git-ssh-proxy.socket"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 10.1.0.1:2222";
      DynamicUser = true;
      PrivateTmp = true;
    };
  };
}
