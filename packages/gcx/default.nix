{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  versionCheckHook,
}:

buildGoModule rec {
  pname = "gcx";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "gcx";
    tag = "v${version}";
    hash = "sha256-Dlg0HT/tW4+nCHLVZHaQR++sR2DRh+00Ueh8cVVSdyM=";
  };

  vendorHash = "sha256-OvIK8sgWUo3t0+oure7+PpU7SFzbLyppyeaWQtKyZXg=";

  subPackages = [ "cmd/gcx" ];
  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd gcx \
      --bash <($out/bin/gcx completion bash) \
      --fish <($out/bin/gcx completion fish) \
      --zsh <($out/bin/gcx completion zsh)
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/gcx";
  versionCheckProgramArg = "--version";

  meta = {
    description = "CLI for managing Grafana and Grafana Cloud resources";
    homepage = "https://github.com/grafana/gcx";
    license = lib.licenses.asl20;
    mainProgram = "gcx";
    platforms = lib.platforms.unix;
  };
}
