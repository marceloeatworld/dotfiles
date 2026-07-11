# Waybar - pinned upstream master with narrow local runtime fixes.
# Source: https://github.com/Alexays/Waybar
#
# Why the master pin: Hyprland 0.55 made `configType = "lua"` the default IPC
# protocol, which broke the legacy `dispatch <name> <args>` syntax used by
# waybar's hyprland/workspaces click handlers. Master adds isLuaProtocol()
# detection and translates dispatches to hl.dsp.* form. Release 0.15.0
# predates this.
#
# To update:
#   1. Latest master: gh api repos/Alexays/Waybar/commits/master --jq .sha
#   2. nix flake prefetch github:Alexays/Waybar/<sha> --json  (use .hash)
#   3. Update rev and hash below
{ waybar, fetchFromGitHub, ... }:

let
  rev = "98b2a563f398f63f99ec8a6f7fb2b19a172abd5d";
  shortRev = builtins.substring 0 7 rev;
  version = "0.15.0-unstable-${shortRev}";
in
(waybar.override {
  # Upstream switched the vendored Cava fallback to `libcava`, while the
  # current nixpkgs package still vendors the older subproject layout.
  # This config does not use Waybar's cava module, so keep the pin buildable.
  cavaSupport = false;
}).overrideAttrs (old: {
  inherit version;

  # The pinned upstream snapshot builds successfully, but its utils test can
  # abort on the SleeperThread timing stress test under the current nixpkgs
  # toolchain. Keep the runtime pin buildable until Waybar's test is stable.
  doCheck = false;
  mesonFlags =
    map
      (flag: if flag == "-Dtests=enabled" then "-Dtests=disabled" else flag)
      (old.mesonFlags or [ ])
    ++ [
      # Upstream master enables WWAN by default, but this configuration does
      # not use that module and the pinned nixpkgs package has no mm-glib input.
      "-Dwwan=disabled"
    ];

  src = fetchFromGitHub {
    owner = "Alexays";
    repo = "Waybar";
    inherit rev;
    hash = "sha256-gVYj72W4L5FJwtfkT/m8PxgDKBT/3HIq1BdnxhFtlPQ=";
  };

  postPatch = (old.postPatch or "") + ''
    substituteInPlace meson.build \
      --replace-fail "version: '0.15.0'," "version: '${version}',"

    # GeoClue support was added shortly before this pin. Upstream subscribes
    # every privacy module instance to GeoClue even when the configured items
    # only cover screen sharing and microphone use. The resulting callback is
    # the exact locationTimeout() path seen in the local SIGSEGV. Do not create
    # that unused subscription; keep the configured PipeWire indicators.
    substituteInPlace src/modules/privacy/privacy.cpp \
      --replace-fail \
'  geoclue_backend = util::GeoClueBackend::GeoClueBackend::getInstance();
  geoclue_backend->in_use_changed_signal_event.connect(
      sigc::mem_fun(*this, &Privacy::onGeoCluePrivacyNodesChanged));' \
'  for (const PrivacyItem* module : modules_) {
    if (module->privacy_type != PRIVACY_NODE_TYPE_LOCATION) continue;

    geoclue_backend = util::GeoClueBackend::GeoClueBackend::getInstance();
    geoclue_backend->in_use_changed_signal_event.connect(
        sigc::mem_fun(*this, &Privacy::onGeoCluePrivacyNodesChanged));
    break;
  }'

    # ath11k can transiently return EBUSY/EIO for GET_STATION. Waybar polls
    # this optional bitrate data for every bar instance, so warning-level logs
    # otherwise flood the user journal while connectivity remains healthy.
    substituteInPlace src/modules/network.cpp \
      --replace-fail \
'        spdlog::warn("nl80211: nl_send_sync get_station error {}", err);' \
'        spdlog::debug("nl80211: nl_send_sync get_station error {}", err);'
  '';
})
