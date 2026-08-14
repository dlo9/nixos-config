set unstable # user-defined functions are unstable
set lists # boolean operators

default:
    build-all

hostname := `hostname`
hardware-config := "hosts/" + hostname + "/hardware/generated.nix"

rebuild_bin := if os() == "android" {
    "nix-on-droid"
} else if os() == "linux" {
    "nixos-rebuild"
} else if os() == "macos" {
    "darwin-rebuild"
} else {
    error(f"Unsupported OS: {{os()}}")
}

config_type := if os() == "android" {
    "nixOnDroidConfigurations"
} else if os() == "linux" {
    "nixosConfigurations"
} else if os() == "macos" {
    "darwinConfigurations"
} else {
    error(f"Unsupported OS: {{os()}}")
}

default_rebuild_args := if os() == "android" {
    "--option fallback true --show-trace"
} else if os() == "linux" {
    "--option fallback true --show-trace"
} else if os() == "macos" {
    "--option fallback true --option http2 false --show-trace"
} else {
    error(f"Unsupported OS: {{os()}}")
}

#################
### FUNCTIONS ###
#################

# Determine if the os/command combo requires sudo for rebuilds
rebuild_sudo(cmd) := if os() != "android" && cmd =~ "^(switch|rollback|test)$" {
    "sudo"
}

# Returns the config type (nixosConfigurations, darwinConfigurations, nixOnDroidConfigurations) for a given host
config_type(host) := shell('''
    nix eval --impure --json --expr '
        let
        f = builtins.getFlake (toString ./.);
        types = [ "nixosConfigurations" "darwinConfigurations" "nixOnDroidConfigurations" ];
        in builtins.listToAttrs (builtins.concatMap (t:
            if f ? ${t}
            then map (n: { name = n; value = t; }) (builtins.attrNames f.${t})
            else []
        ) types)
    ' | jq -r --arg n "$1" '.[$n] // empty'
''', host)

deploy_args(host) := if host == "pixie" {
    "--impure"
}

###############
### RECIPES ###
###############

_restrict_to_host host:
    @if [[ "{{hostname}}" != "{{host}}" ]]; then echo "Only supported on {{host}}"; exit 1; fi

alias fmt := format
format:
    alejandra fmt -q .

forecast host=hostname:
    nix run nixpkgs#nix-forecast -- -c ".#{{config_type(host)}}.{{host}}" --show-missing

rebuild cmd="build" host=hostname:
    {{rebuild_sudo(cmd)}} {{rebuild_bin}} --flake ".#{{host}}" {{cmd}} {{default_rebuild_args}} |& nom

build host=hostname: (rebuild "build" host)
switch host=hostname: (rebuild "switch" host)
test host=hostname: (rebuild "test" host)

generate-hardware: && format
    mkdir -p "$(dirname "{{hardware-config}}")"

    # Ask for sudo now, so that the file isn't truncated if sudo fails
    sudo -v

    # Must use `sudo` so that all mounts are visible
    sudo nixos-generate-config --show-hardware-config | \
        scripts/maintenance/process-hardware-config.awk > "{{hardware-config}}"

# Does a remote deployment
deploy host: format
    nix run nixpkgs#deploy-rs -- --skip-checks --auto-rollback false --magic-rollback false -k .#{{host}} -- {{deploy_args(host)}}

bootstrap-pixie:
    # Make sure to start SSH on the host:
    # nix run github:dlo9/nixos-config#nix-on-droid-ssh

    # Copy age key to host
    sops -d --extract '["age-key"]["contents"]' hosts/pixie/secrets.yaml | \
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        pixie 'cat > ./.config/sops-age-keys.txt'

    # Deploy
    nix run nixpkgs#deploy-rs -- \
        --skip-checks --auto-rollback false --magic-rollback false -k \
        --ssh-opts "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
        --targets .#pixie -- \
        --impure

deploy-all:
    # https://github.com/serokell/deploy-rs/issues/325#issuecomment-3015838438
    nix run github:serokell/deploy-rs/5829cec -- --skip-checks --auto-rollback false --magic-rollback false -k --targets .#cuttlefish .#drywell .#pavil .#trident
    nix run github:serokell/deploy-rs/5829cec -- --skip-checks --auto-rollback false --magic-rollback false -k --targets .#pixie -- --impure

vm host=hostname:
    nixos-rebuild build-vm --flake ".#{{host}}" --show-trace |& nom
    QEMU_OPTS="-m 4096 -smp 2 -enable-kvm -vga none -device virtio-vga-gl -display gtk,gl=on" ./result/bin/run-{{host}}-vm

update: && format
    nix flake update

gc:
    # Run as sudo to collect generations on darwin:
    # https://github.com/nix-darwin/nix-darwin/issues/237#issuecomment-2032089213
    sudo nix-collect-garbage -d

# Generate a package definition from a source URL with nix-init (writes pkgs/<name>.nix)
add-package url name: && format
    nix run nixpkgs#nix-init -- --url "{{url}}" "pkgs/{{name}}.nix"

refresh-k8s-certs: (_restrict_to_host "cuttlefish")
    sudo rm -rf /var/lib/cfssl /var/lib/kubernetes/secrets
    sudo systemctl restart cfssl
    sleep 5
    sudo systemctl restart certmgr
    until [ -f /var/lib/kubernetes/secrets/cluster-admin-key.pem ]; do sleep 1; done
    sudo systemctl restart kubernetes.slice
    sudo chown david /var/lib/kubernetes/secrets/cluster-admin-key.pem
