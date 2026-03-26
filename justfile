default:
    build-all

hostname := `hostname`
hardware-config := "hosts/" + hostname + "/hardware/generated.nix"

alias fmt := format
format:
    alejandra fmt -q .

rebuild-linux cmd="build" host=hostname:
    sudo -v # Nom has an issue with hiding the sudo message
    sudo nixos-rebuild --flake ".#{{host}}" {{cmd}} --option fallback true --show-trace |& nom

rebuild-macos cmd="build" host=hostname:
    sudo -v # Nom has an issue with hiding the sudo message
    sudo darwin-rebuild --flake ".#{{host}}" {{cmd}} --option fallback true --option http2 false --show-trace |& nom

rebuild-android cmd="build" host=hostname:
    nix-on-droid --flake ".#{{host}}" {{cmd}} --option fallback true --show-trace |& nom

build host=hostname:
    just "rebuild-{{os()}}" build {{host}}

switch host=hostname:
    just "rebuild-{{os()}}" switch {{host}}
    just format

test host=hostname:
    just "rebuild-{{os()}}" test {{host}}
    just format

generate-hardware: && format
    mkdir -p "$(dirname "{{hardware-config}}")"

    # Ask for sudo now, so that the file isn't truncated if sudo fails
    sudo -v

    # Must use `sudo` so that all mounts are visible
    sudo nixos-generate-config --show-hardware-config | \
        scripts/maintenance/process-hardware-config.awk > "{{hardware-config}}"

# Does a remote deployment
deploy host:
    #!/bin/sh

    case "{{host}}" in
        pixie) args="-- --impure" ;;
    esac

    nix run nixpkgs#deploy-rs -- --skip-checks --auto-rollback false --magic-rollback false -k .#{{host}} $args
    just format

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

update:
    nix flake update
    just format
