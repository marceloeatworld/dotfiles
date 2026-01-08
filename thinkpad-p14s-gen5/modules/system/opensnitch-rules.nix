# OpenSnitch firewall rules
# Block unwanted telemetry, trackers, and analytics
{ ... }:

{
  services.opensnitch.rules = {
    # ══════════════════════════════════════════════════════════════════════════
    # MICROSOFT TELEMETRY
    # ══════════════════════════════════════════════════════════════════════════
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

    block-microsoft-telemetry-2 = {
      name = "block-microsoft-telemetry-2";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*telemetry\\.microsoft\\.com$";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # BRAVE BROWSER
    # ══════════════════════════════════════════════════════════════════════════
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

    block-brave-rewards = {
      name = "block-brave-rewards";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*rewards\\.brave\\.com$";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # GOOGLE ANALYTICS & TRACKING
    # ══════════════════════════════════════════════════════════════════════════
    block-google-analytics = {
      name = "block-google-analytics";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.google-analytics\\.com$";
      };
    };

    block-google-doubleclick = {
      name = "block-google-doubleclick";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.doubleclick\\.net$";
      };
    };

    block-google-ads = {
      name = "block-google-ads";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.googlesyndication\\.com$";
      };
    };

    block-googleadservices = {
      name = "block-googleadservices";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.googleadservices\\.com$";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # FACEBOOK / META TRACKING
    # ══════════════════════════════════════════════════════════════════════════
    block-facebook-pixel = {
      name = "block-facebook-pixel";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "simple";
        operand = "dest.host";
        data = "pixel.facebook.com";
      };
    };

    block-facebook-analytics = {
      name = "block-facebook-analytics";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "simple";
        operand = "dest.host";
        data = "analytics.facebook.com";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # COMMON TRACKERS & ANALYTICS
    # ══════════════════════════════════════════════════════════════════════════
    block-hotjar = {
      name = "block-hotjar";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.hotjar\\.com$";
      };
    };

    block-mixpanel = {
      name = "block-mixpanel";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.mixpanel\\.com$";
      };
    };

    block-segment = {
      name = "block-segment";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.segment\\.io$";
      };
    };

    block-amplitude = {
      name = "block-amplitude";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.amplitude\\.com$";
      };
    };

    block-fullstory = {
      name = "block-fullstory";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.fullstory\\.com$";
      };
    };

    block-newrelic = {
      name = "block-newrelic";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.newrelic\\.com$";
      };
    };

    block-sentry = {
      name = "block-sentry";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.sentry\\.io$";
      };
    };

    block-bugsnag = {
      name = "block-bugsnag";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.bugsnag\\.com$";
      };
    };

    block-crashlytics = {
      name = "block-crashlytics";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.crashlytics\\.com$";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # ADVERTISING NETWORKS
    # ══════════════════════════════════════════════════════════════════════════
    block-adroll = {
      name = "block-adroll";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.adroll\\.com$";
      };
    };

    block-criteo = {
      name = "block-criteo";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.criteo\\.com$";
      };
    };

    block-outbrain = {
      name = "block-outbrain";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.outbrain\\.com$";
      };
    };

    block-taboola = {
      name = "block-taboola";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.taboola\\.com$";
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # APP TELEMETRY
    # ══════════════════════════════════════════════════════════════════════════
    block-appsflyer = {
      name = "block-appsflyer";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.appsflyer\\.com$";
      };
    };

    block-adjust = {
      name = "block-adjust";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.adjust\\.com$";
      };
    };

    block-branch = {
      name = "block-branch";
      enabled = true;
      action = "deny";
      duration = "always";
      operator = {
        type = "regexp";
        operand = "dest.host";
        data = ".*\\.branch\\.io$";
      };
    };
  };
}
