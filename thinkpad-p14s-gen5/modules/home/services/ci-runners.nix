# GitHub Actions runners on this machine, one per repository. CI minutes on a machine of ours
# are not billed. A personal GitHub account cannot register one runner for several
# repositories, so every repository gets its own.
#
# A runner is a rootless Podman container named `<repo>-runner`, made once by hand and
# registered with a one-hour token (amberq: docs/production.md, section 3.1, and the image in
# its `ops/runner`). Nothing here names a repository: at login `ci-runners` starts
# `ci-runner@<repo>` for every such container. After making a new container, run
# `systemctl --user start ci-runners`.
#
# Stop one repository's CI on this machine: `systemctl --user stop ci-runner@<repo>`. Stop
# all: `systemctl --user stop 'ci-runner@*'`. Send the jobs back to GitHub's machines:
# `gh variable delete CI_RUNNER` in the repository, when its workflows read that variable.
#
# Never make a runner for a repository that takes pull requests from strangers: their code
# would run on this machine.
{ pkgs, ... }:

let
  # The system's own Podman: rootless containers need its setuid helpers in /run/wrappers.
  podman = "/run/current-system/sw/bin/podman";

  startAll = pkgs.writeShellScript "ci-runners-start" ''
    ${podman} ps -a --format '{{.Names}}' \
      | ${pkgs.gnused}/bin/sed -n 's/-runner$//p' \
      | while read -r repo; do
          ${pkgs.systemd}/bin/systemctl --user start --no-block "ci-runner@$repo"
        done
  '';
in
{
  systemd.user.services."ci-runner@" = {
    Unit = {
      Description = "GitHub Actions runner for %i (container)";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecCondition = "${podman} container exists %i-runner";
      ExecStart = "${podman} start -a %i-runner";
      ExecStop = "${podman} stop -t 30 %i-runner";
      Restart = "on-failure";
      RestartSec = 15;
    };
  };

  systemd.user.services.ci-runners = {
    Unit.Description = "Start a GitHub Actions runner for every <repo>-runner container";
    Service = {
      Type = "oneshot";
      ExecStart = "${startAll}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
