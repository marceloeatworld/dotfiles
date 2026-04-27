# Hermes Agent CLI with profiles for local LLM + cloud API
# Profiles are managed imperatively after install:
#   hermes profile create local   → offline fallback via llama-cpp (port 8080, Qwen3.5 4B/9B)
#   hermes profile create coder   → z.ai GLM-5 coding agent (primary)
#   hermes profile create minimax → MiniMax 2.7 (MINIMAX_API_KEY)
{ inputs, pkgs, ... }:

let
  hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment.systemPackages = [
    hermesPackage
  ];

  # Keep Hermes state in the invoking user's home. The gateway service is not
  # enabled because no messaging platform is configured on this machine.
  environment.variables.HERMES_HOME = "$HOME/.hermes";
}
