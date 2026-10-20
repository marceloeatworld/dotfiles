# Local PostgreSQL for Medusa development (localhost only).
# `create-medusa-app` and `medusa db:setup` connect over TCP to
# localhost:5432 and create their own databases, so TCP connections from
# this machine use trust auth and the `marcelo` role is a superuser.
# Nothing is exposed on the network: listen_addresses stays "localhost"
# (enableTCPIP is off) and the firewall does not open 5432.
{ pkgs, lib, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18; # same major as the psql client in development.nix
    ensureUsers = [
      {
        name = "marcelo";
        ensureClauses = {
          superuser = true;
          createdb = true;
          login = true;
        };
      }
    ];
    # Added above the NixOS defaults (peer on the socket, md5 on TCP).
    authentication = ''
      host all all 127.0.0.1/32 trust
      host all all ::1/128      trust
    '';
  };
}
