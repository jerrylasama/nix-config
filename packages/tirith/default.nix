{
  fetchurl,
  glibc ? null,
  lib,
  patchelf ? null,
  stdenvNoCC,
}:
# Tirith (tirith.sh) terminal security gate. Pinned here because nixpkgs lags
# at 0.3.3. 0.4.x refuses to execute inside a nix build sandbox (its
# anti-tampering check reads the store binary as uid 65534), so its generated
# pi extension and codex gateway file are vendored under dotfiles/ instead of
# run from a runCommand. Re-vendor both on every version bump; see
# aspects/agents.nix.
let
  version = "0.4.2";
  platform =
    {
      x86_64-linux = {
        upstream = "x86_64-unknown-linux-gnu";
        hash = "sha256-76a/QUqD26OF1PExN+hnf4UM7ZEC/nTrsUxy8x3w3Hc=";
        loader = "ld-linux-x86-64.so.2";
      };
      aarch64-linux = {
        upstream = "aarch64-unknown-linux-musl";
        hash = "sha256-nIboFTfce3/mZV6kcnKLX3oNvpPrtouVynYB+xq6BQg=";
        loader = null;
      };
      aarch64-darwin = {
        upstream = "aarch64-apple-darwin";
        hash = "sha256-VR+abr9YNE59CqBrzHjXpPL3tEuAEb5WPgqRl2zJxN8=";
        loader = null;
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "tirith ${version} is not pinned for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "tirith";
  inherit version;

  src = fetchurl {
    url = "https://github.com/sheeki03/tirith/releases/download/v${version}/tirith-${platform.upstream}.tar.gz";
    inherit (platform) hash;
  };

  nativeBuildInputs = lib.optional (platform.loader != null) patchelf;

  # The tarball has several top-level entries (binaries, completions, man),
  # which defeats stdenv's single-directory sourceRoot detection.
  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/tirith" "$out/bin" "$out/share"
    install -m755 tirith "$out/lib/tirith/"
    # Only the Linux builds carry the package-approval authority.
    if [ -e tirith-package-approval-authority ]; then
      install -m755 tirith-package-approval-authority "$out/lib/tirith/"
    fi

    ${
      if platform.loader != null then
        ''
          patchelf --set-interpreter "${glibc}/lib/${platform.loader}" \
            "$out/lib/tirith/tirith"
          if [ -e "$out/lib/tirith/tirith-package-approval-authority" ]; then
            patchelf --set-interpreter "${glibc}/lib/${platform.loader}" \
              "$out/lib/tirith/tirith-package-approval-authority"
          fi
        ''
      else
        "true"
    }

    ln -s "$out/lib/tirith/tirith" "$out/bin/tirith"
    if [ -e "$out/lib/tirith/tirith-package-approval-authority" ]; then
      ln -s "$out/lib/tirith/tirith-package-approval-authority" \
        "$out/bin/tirith-package-approval-authority"
    fi
    if [ -d completions ]; then
      cp -r completions "$out/share/"
    fi
    if [ -f man/tirith.1 ]; then
      mkdir -p "$out/share/man/man1"
      install -m644 man/tirith.1 "$out/share/man/man1/"
    fi
    runHook postInstall
  '';

  passthru = { inherit version; };

  meta = {
    description = "Terminal security gate: homograph URLs, obfuscated payloads, exfiltration, threat intel";
    homepage = "https://tirith.sh";
    license = lib.licenses.agpl3Only;
    mainProgram = "tirith";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
