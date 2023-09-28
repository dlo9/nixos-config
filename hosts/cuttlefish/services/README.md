# Debugging
```sh
sudo machinectl shell keycloak
sudo journalctl -M keycloak
journalctl -u container@keycloak.service
To remove state: https://github.com/NixOS/nixpkgs/commit/3877ec5b2ff7436f4962ac0fe3200833cf78cb8b#commitcomment-19100105
```

# Kubernetes

# Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd container: failed to stat parent: stat /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/10524/fs: no such file or directory
```sh
sudo rm -rf /var/lib/containerd/io.containerd.grpc.v1.cri/sandboxes/
sudo crictl rmp -a

for i in (seq 1 3); sudo ctr -n k8s.io snapshot ls | awk '$1 ~ /^sha256/ && $3 != "Active" {print $1}' | xargs -n1 sudo ctr -n k8s.io snapshot rm; end

# Check status:
kubectl get pod -A | rg -v 'Running|Completed'
```