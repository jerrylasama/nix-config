# Prebuilt Pi-Bolt (https://github.com/opensec-git/Pi-Bolt), the AOT-compiled
# fork of the pi coding agent. Version-pinned release tarballs; hashes come
# from the SHA256SUMS asset of the release. To bump, update `version` and
# refresh both hashes together from the new release's SHA256SUMS.
# The tarball is a directory tree: `pi` is a small launcher that must keep its
# siblings (`pi-bin` is the ~200 MB AOT executable, `pi-bin.hot` the prebuilt
# heap, plus wasm assets), so the whole tree is installed and only symlinked
# into bin/. Pi-Bolt reads the same ~/.pi/agent as pi, so sessions, settings
# and extensions carry over.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libxcb,
}:

let
  version = "0.8.3";
  variants = {
    x86_64-linux = {
      tarball = "pi-bolt-linux-x64";
      hash = "sha256-+7C730+kVf/2/CKB7258DYXN92Fc3cIqVbmFOv0ABuo=";
    };
    aarch64-darwin = {
      tarball = "pi-bolt-darwin-arm64";
      hash = "sha256-ABptZBM7oxt0J20jlNt/3kWvCScdBlnODA3SACXUQfk=";
    };
  };
  variant =
    variants.${stdenv.hostPlatform.system}
      or (throw "pi-bolt: no upstream release tarball for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "pi-bolt";
  inherit version;

  src = fetchurl {
    url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${variant.tarball}.tar.xz";
    hash = variant.hash;
  };

  sourceRoot = variant.tarball;

  # The Linux build is a prebuilt Bun AOT executable; link it against the
  # host's glibc and libstdc++. The macOS build is already linked and signed,
  # so nothing patches it.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    # linux-platform-x11.node links against libxcb.so.1
    libxcb
  ];

  # Prebuilt binaries: leave them byte-for-byte intact.
  dontStrip = true;
  dontPatchELF = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/pi-bolt" "$out/bin"
    cp -a . "$out/lib/pi-bolt/"
    ln -s "$out/lib/pi-bolt/pi" "$out/bin/pi"
    ln -s "$out/lib/pi-bolt/pi" "$out/bin/pi-bolt"
    runHook postInstall
  '';

  meta = {
    description = "Pi coding agent compiled ahead of time to native code (Pi-Bolt)";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
