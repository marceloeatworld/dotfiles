{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "x-cli";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "tamnd";
    repo = "x-cli";
    rev = "v${version}";
    hash = "sha256-2aN/W0wj6DHhN5UguCskO28ZZMawWiyH2Kl8WP4R66E=";
  };

  vendorHash = "sha256-PhQl3MFQcpNjeGz24O9ac8ezqAQ9yXlC7TayHk1yaRY=";

  subPackages = [ "cmd/x" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/tamnd/x-cli/cli.Version=v${version}"
    "-X github.com/tamnd/x-cli/cli.Commit=v${version}"
    "-X github.com/tamnd/x-cli/cli.Date=reproducible"
  ];

  meta = {
    description = "Read-only CLI for X public and browser-session surfaces";
    homepage = "https://github.com/tamnd/x-cli";
    license = lib.licenses.agpl3Only;
    mainProgram = "x";
    platforms = lib.platforms.linux;
  };
}
