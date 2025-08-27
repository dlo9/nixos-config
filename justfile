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

deploy-all:
    # https://github.com/serokell/deploy-rs/issues/325#issuecomment-3015838438
    nix run github:serokell/deploy-rs/5829cec -- --skip-checks --auto-rollback false --magic-rollback false -k --targets .#cuttlefish .#drywell .#pavil .#trident
    nix run github:serokell/deploy-rs/5829cec -- --skip-checks --auto-rollback false --magic-rollback false -k --targets .#pixie -- --impure

update:
    nix flake update
