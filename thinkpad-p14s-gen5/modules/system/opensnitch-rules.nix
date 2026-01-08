# OpenSnitch firewall rules
# Block unwanted telemetry and services
{ ... }:

{
  services.opensnitch.rules = {
    # Block Microsoft telemetry (watson.events.data.microsoft.com, etc.)
    block-microsoft-telemetry = {
      name = "block-microsoft-telemetry";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.data\\.microsoft\\.com$";
      };
    };

    # Block Brave browser sync
    block-brave-sync = {
      name = "block-brave-sync";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "simple";
        operand = "dest.host";
        data = "sync-v2.brave.com";
      };
    };
  };
}
