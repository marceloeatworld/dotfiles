# Brave policies (Chromium policy files under /etc/brave/policies).
# The firejail Brave profile (security.nix) has no private-etc, so the jail
# sees these files.
{ ... }:

{
  programs.chromium = {
    enable = true;

    # Managed (locked). Telemetry and leak surfaces only; features the
    # profile uses (Wallet with a seed, Leo, News, Sync) are left alone.
    # Audit of ~/.config/BraveSoftware/Brave-Browser on 2026-11-03: crash
    # reporting was on, everything else here was at the Chromium default.
    extraOpts = {
      MetricsReportingEnabled = false; # crash and usage reports
      BraveP3AEnabled = false; # Brave privacy-preserving analytics
      BraveStatsPingEnabled = false; # daily usage ping
      UrlKeyedAnonymizedDataCollectionEnabled = false;
      WebRtcIPHandling = "default_public_interface_only"; # no local IP leak via WebRTC
      NetworkPredictionOptions = 2; # no preconnect or prefetch
      EnableMediaRouter = false; # Chromecast discovery
      BackgroundModeEnabled = false;
      SpellCheckServiceEnabled = false; # Google spellcheck service
      AlternateErrorPagesEnabled = false;
      PasswordManagerEnabled = false; # Proton Pass extension is the manager
      AutofillCreditCardEnabled = false;
      AutofillAddressEnabled = false;
    };

    # Recommended, not managed: Brave applies these as defaults but
    # brave://settings/search can still override them.
    extraOptsRecommended = {
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "SearXNG";
      DefaultSearchProviderKeyword = "sx";
      DefaultSearchProviderSearchURL = "https://sear66.aitek.tech/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://sear66.aitek.tech/autocompleter?q={searchTerms}";
      DefaultSearchProviderIconURL = "https://sear66.aitek.tech/favicon.ico";
    };
  };
}
