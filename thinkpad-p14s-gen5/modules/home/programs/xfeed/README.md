# XFeed

Lightweight X home-timeline panel for Ghostty and Hyprland.

## Privacy boundary

The repository contains no account ID, username, API key, or session cookie.
`xfeed-configure` imports the `auth_token` and `ct0` cookies at runtime into:

```text
~/.local/share/xfeed/x-cli/session.json
```

The directory and file are created with modes `700` and `600`. Cookies are
not copied to the Nix store. Cookies are passed to `x auth import` through
stdin, so they do not appear in process arguments or shell history.

The session is consumed by the pinned read-only
[`tamnd/x-cli`](https://github.com/tamnd/x-cli) GraphQL client. Version `0.4.0`
was reviewed before integration: it has no commands that post, like, follow, or
otherwise modify the account. It sends session cookies only to X GraphQL
requests. It separately downloads a public transaction-ID dictionary from
GitHub without attaching session headers.

## Setup

No developer account, paid API credit, OAuth app, or numeric user ID is needed.
The session cookies come from an already logged-in `x.com` tab in Brave:

1. Open Developer Tools with `F12`.
2. Open `Application` -> `Storage` -> `Cookies` -> `https://x.com`.
3. Copy the values of `auth_token` and `ct0` when prompted by
   `xfeed-configure`.

`auth_token` is effectively a logged-in browser session. Never paste it into
chat or commit it. Using private X GraphQL endpoints is unsupported, can break
without notice, violates X's automation rules, and can lead to account
restriction or suspension.

After applying the NixOS configuration:

```sh
xfeed-configure
xfeed-control enable
```

Press `Super+R` to show or hide the panel.

The panel is deliberately Conky-like: it has no border, shadow, scrollbar, or
resize overlay. It renders two to four compact posts at a time depending on
the terminal height. Resizing redraws every visible card and fits each image
inside its new space without changing its aspect ratio.

## Controls

- `Space`: pause or resume
- `j` / `k`: select a visible post
- `n`: next group of posts
- `+` / `-`: change the delay
- `o` or `Enter`: open the selected post
- `r`: refresh
- `q`: close

`xfeed-control disable` stops the panel while preserving local session cookies.
`xfeed-control purge` removes its cookies, cache, and state after
confirmation.

## Removal

1. Run `xfeed-control purge` if local data should also be removed.
2. Remove `./programs/xfeed` from `modules/home/home.nix`.
3. Delete this directory.
4. Rebuild the configuration.

No other repository file owns XFeed configuration.
