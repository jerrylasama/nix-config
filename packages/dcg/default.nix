{
  fetchurl,
  lib,
  stdenvNoCC,
}:
let
  version = "0.14.3";
  assets = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-oDnZUDh/y/VGAyIAjShcwGwZNkt2flvEonJaeOGHepc=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-7jNjjfOOKnkezyqMMpaLQ7u2k495TDtq7PxTkRvaNdk=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-Y3Ev19xUn2CGQMQVRb49hobBTouYnlEZS1SpkLQlX2k=";
    };
  };
  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "dcg: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "dcg";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Dicklesworthstone/destructive_command_guard/releases/download/v${version}/dcg-${asset.target}.tar.xz";
    inherit (asset) hash;
  };

  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    install -Dm755 dcg "$out/bin/dcg"
    runHook postInstall
  '';

  meta = {
    description = "Guard against destructive commands run by AI coding agents";
    homepage = "https://github.com/Dicklesworthstone/destructive_command_guard";
    license = lib.licenses.mit;
    mainProgram = "dcg";
    platforms = builtins.attrNames assets;
  };
}
