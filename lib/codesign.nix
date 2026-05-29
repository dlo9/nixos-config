# Runtime code-signing for macOS.
#
# macOS TCC pins Accessibility / Full Disk Access grants to a binary's code
# signature, but nix signs ad-hoc with a per-build cdhash, so every rebuild
# revokes the grant. `signPackage` wraps a package so its bin/ executables are
# symlinks into a per-user cache of copies re-signed with a stable self-signed
# cert (the `codesign-key` sops secret). The signing itself is done on
# activation by `mkSignScript` (a symlink is passive) — see home/codesign.nix.
#
# Because launchd exec-follows the symlink, the kernel loads the signed copy
# directly (no wrapper-exec hop), which is what TCC evaluates. The cache path is
# stable (no version/hash in it) so the binary's path never changes between
# rebuilds — important because TCC may key a bare binary's grant on its path, so
# a changing path could force re-approval. On activation we re-sign into a temp
# and only swap it in (restarting the daemon) when its cdhash differs from the
# cached copy, so an unchanged package/cert is a no-op. The cdhash captures the
# code + identifier + signing cert, so both package updates and cert rotations
# are picked up automatically.
{
  lib,
  runCommand,
  coreutils,
}: let
  signPackage = {
    package,
    # Absolute home dir. Required: a symlink target is baked at build time and
    # must be an absolute literal, not a runtime "$HOME".
    home,
    # bin/ executables to sign; defaults to the package's main program.
    names ? [(package.meta.mainProgram or package.pname)],
    # TCC identifier; a string (applied to every name) or a name -> id function.
    identifier ? (name: name),
    cacheDir ? "${home}/.cache/nix-codesign",
  }: let
    idOf = name:
      if lib.isString identifier
      then identifier
      else identifier name;

    entries =
      map (name: {
        inherit name;
        identifier = idOf name;
        src = "${package}/bin/${name}";
        cachePath = "${cacheDir}/${name}";
      })
      names;

    # Space-padded for a substring membership test in the build script.
    nameSet = " ${lib.concatStringsSep " " names} ";
  in
    runCommand "${package.name}-signed" {
      inherit (package) meta;
      passthru =
        (package.passthru or {})
        // {
          unsigned = package;
          codesignSpec = {inherit entries;};
        };
    } ''
      set -eu
      in="${package}"
      mkdir -p "$out"

      # Mirror every top-level entry as a symlink (share/, Library/, ...).
      for e in "$in"/*; do
        ln -s "$e" "$out/$(${coreutils}/bin/basename "$e")"
      done

      # Rebuild bin/: symlink each entry, except the wrapped names which point
      # at the (activation-populated) signed cache copy.
      if [ -d "$in/bin" ]; then
        rm -f "$out/bin"
        mkdir -p "$out/bin"
        for f in "$in/bin/"*; do
          name="$(${coreutils}/bin/basename "$f")"
          case "${nameSet}" in
            *" $name "*) ln -s "${cacheDir}/$name" "$out/bin/$name" ;;
            *) ln -s "$f" "$out/bin/$name" ;;
          esac
        done
      fi
    '';

  # POSIX-sh activation snippet (for home.activation) that populates the signed
  # cache for each spec entry and re-signs any app bundles in place. `specs` is
  # a list of `passthru.codesignSpec` values; `bundles` a list of .app paths.
  mkSignScript = {
    rcodesign,
    specs ? [],
    bundles ? [],
    keyFile ? "/run/secrets/codesign-key",
  }: let
    entries = lib.concatMap (s: s.entries) specs;

    # codesign_bin only publishes (and we only restart) when the signature
    # actually changed, so unchanged rebuilds don't churn the daemons.
    signEntry = e: ''
      if codesign_bin "${e.src}" "${e.identifier}" "${e.cachePath}"; then
        /usr/bin/pkill -x "${e.name}" 2>/dev/null || true
      fi
    '';

    signBundle = app: ''
      if [ -d "${app}" ]; then
        /bin/chmod -R u+w "${app}"
        # Keep the bundle's own identifier (CFBundleIdentifier); just re-sign.
        "$rcodesign" sign --pem-file "$key" "${app}" >/dev/null
      fi
    '';
  in ''
    key="${keyFile}"
    rcodesign="${rcodesign}/bin/rcodesign"

    if [ ! -f "$key" ]; then
      echo "codesign: key $key not found; skipping (sops not deployed yet?)." >&2
    else
      # cdhash of a signed binary — stable across re-signs of the same code +
      # identifier + cert (the signing timestamp lives in the CMS blob, not the
      # CodeDirectory), so it's a reliable "is this already what we'd produce".
      cdhash() {
        /usr/bin/codesign -dvvv "$1" 2>&1 | /usr/bin/awk -F= '/^CDHash=/{print $2; exit}'
      }

      # Sign $1 (store binary) -> $3 (stable cache path) with identifier $2. Sign
      # into a temp and only swap it in when its cdhash differs from the cached
      # copy, so an unchanged package/cert is a no-op. mv is atomic and safe even
      # while the old copy is running. Returns 0 if (re)published, 1 otherwise.
      codesign_bin() {
        src="$1"; id="$2"; dest="$3"
        /bin/mkdir -p "$(${coreutils}/bin/dirname "$dest")"
        tmp="$(/usr/bin/mktemp "$dest.XXXXXX")"
        /bin/cp -f "$src" "$tmp"
        /bin/chmod u+w "$tmp"
        if ! "$rcodesign" sign --pem-file "$key" --binary-identifier "$id" "$tmp" >/dev/null 2>&1; then
          /bin/rm -f "$tmp"
          echo "codesign: failed to sign $src" >&2
          return 1
        fi
        if [ -x "$dest" ] && [ "$(cdhash "$tmp")" = "$(cdhash "$dest")" ]; then
          /bin/rm -f "$tmp"
          return 1
        fi
        /bin/chmod a+x "$tmp"
        /bin/mv -f "$tmp" "$dest"
        return 0
      }

      ${lib.concatMapStringsSep "\n" signEntry entries}
      ${lib.concatMapStringsSep "\n" signBundle bundles}
    fi
  '';
in {
  inherit signPackage mkSignScript;
}
