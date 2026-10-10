{
  lib,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
}:

# The bundled skill directory is embedded at build time (build.rs), so the
# binary carries its own copy of browser-skill; no separate skill install.
# The read-only store path also disables the daemon's self-update: it only
# reports new releases. Update by bumping `version` and refreshing the hash.
rustPlatform.buildRustPackage rec {
  pname = "bsk";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "Tencent";
    repo = "BrowserSkill";
    tag = "cli-v${version}";
    hash = "sha256-daYgT59gDpZqLIRbmCwf9p8tsHhdR+OmVjUUhVVzqGM=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  # Test suites reach for a browser and a running daemon; skip them.
  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/bsk";
  versionCheckProgramArg = "--version";

  meta = {
    description = "Connect AI agents to Chrome or Edge through the BrowserSkill extension";
    homepage = "https://github.com/Tencent/BrowserSkill";
    changelog = "https://github.com/Tencent/BrowserSkill/blob/${src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "bsk";
    platforms = lib.platforms.unix;
  };
}
