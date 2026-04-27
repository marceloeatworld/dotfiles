# Terminal cheatsheet command (`keys`)
{ pkgs, ... }:

let
  keysContent = ''
    ━━━━━━━━━━━━━━━ HYPRLAND ━━━━━━━━━━━━━━━
    Super+Enter     Terminal (Ghostty)
    Super+B         Browser (Brave)
    Super+E         File manager (Nemo)
    Super+D         App launcher (Hyprlauncher)
    Super+A         Audio control panel
    Super+Y         YouTube PiP (toggle show/hide)
    Super+U         Twitch PiP (toggle show/hide)
    Super+Q         Close window
    Super+Shift+Q   Force kill window
    Super+O         Quick notes
    Super+I         System info panel
    Super+Shift+I   Detailed system info
    Super+X         Malware lab menu
    Super+Z         Freeze/unfreeze focused app
    Super+F1        Keybindings cheatsheet

    ━━━━━━━━━━━━━ WINDOWS ━━━━━━━━━━━━━
    Super+F         Fullscreen
    Super+Shift+F   Fullscreen (keep bar)
    Super+Space     Toggle floating
    Super+P         Pin (all workspaces)
    Super+W         Center floating window
    Super+T         Toggle split (H/V)
    Super+Tab       Last focused window
    Alt+Tab         Next window
    Alt+Shift+Tab   Previous window
    Super+H/J/K/L       Move focus
    Super+Shift+HJKL    Move window
    Super+Ctrl+HJKL     Resize window (40px)
    Super+Ctrl+Shift+HJKL Swap tiled windows
    Super+Mouse L       Move window (drag)
    Super+Mouse R       Resize window (drag)
      Floating windows snap to edges/other windows

    ━━━━━━━━━━━━ GROUPS (TABS) ━━━━━━━━━━━━
    Super+G         Toggle group
    Super+Shift+G   Lock group
    Super+[ / ]     Prev/next tab in group
    Super+Ctrl+[ / ] Reorder tab in group
      Drag windows into groups to tab them

    ━━━━━━━━━━━━ WORKSPACES ━━━━━━━━━━━━
    Super+1-9/0     Workspace 1-10
    Super+Shift+1-9/0 Move window to WS 1-10
    Super+Ctrl+1-5  Focus WS on current monitor
    Super+Shift+Tab Swap workspaces between monitors
    Super+Ctrl+M    Move current WS to next monitor
    Super+Alt+H/L   Move window to prev/next WS
    Super+S         Special workspace
    Super+Shift+S   Move to special WS
    Super+minus     Minimize to special
    Super+Shift+minus  Show minimized
    3-finger swipe  Switch workspace (touchpad+touch)

    ━━━━━━━━━━━━━━━ UTILS ━━━━━━━━━━━━━━━
    Super+V         Clipboard history
    Super+Shift+V   Clear clipboard
    Super+C         Color picker
    Super+N         Blue light filter (cycle 8 levels)
    Super+Shift+N   Blue light off
    Super+M         Battery mode (55-60/75-80/95-100%)
    Super+Shift+M   Performance mode (battery/balanced/max)
    Super+Shift+T   Toggle touchpad
    Super+Shift+C   Window inspector (hyprprop)
    Super+Shift+R   Restart Waybar

    ━━━━━━━━━━━━ SCREENSHOTS ━━━━━━━━━━━━
    Print              Region -> clipboard
    Super+Print        Region -> file
    Shift+Print        Full screen -> clipboard
    Super+Shift+Print  Full screen -> file
    Super+Ctrl+Print   Active window -> clipboard

    ━━━━━━━━━━━━━ SYSTEM ━━━━━━━━━━━━━
    Super+Esc            Lock screen
    Super+Shift+Esc      Power off
    Super+Ctrl+Esc       Reboot
    Super+Alt+Esc        Suspend to RAM
    Super+Ctrl+Shift+Esc  Monitors off

    ━━━━━━━━━━━━ KEYBOARD ━━━━━━━━━━━━
    Super+F3         Switch layout (FR ↔ US)
      Waybar: click language indicator

    ━━━━━━━━━━━━━━ WIFI ━━━━━━━━━━━━━━
    Super+F2         Reconnect WiFi
    Super+Shift+F2   Scan & connect (wofi menu)
    Super+Ctrl+F2    Toggle WiFi on/off
    captive-on       Bypass DNS (portals)
    captive-off      Restore secure DNS

    ━━━━━━━━━━━━━ MEDIA ━━━━━━━━━━━━━
    Volume keys      Volume up/down/mute (SwayOSD)
    Brightness keys  Brightness up/down (SwayOSD)
    Play/Pause       Media play/pause
    Next/Prev        Media next/prev
    Stop             Media stop
    Mic Mute         Microphone toggle

    ━━━━━━━━━━━━ GHOSTTY ━━━━━━━━━━━━
    Ctrl+Shift+T           New tab
    Ctrl+Shift+W           Close tab
    Ctrl+Shift+Right/Left  Next/prev tab
    Ctrl+Shift+1-5         Go to tab 1-5
    Ctrl+Shift+Enter       Split down
    Ctrl+Shift+\           Split right
    Ctrl+Alt+Enter         Split up
    Ctrl+Alt+\             Split left
    Ctrl+Shift+H/J/K/L    Navigate splits
    Ctrl+Alt+H/J/K/L      Resize splits
    Ctrl+Shift+E           Equalize splits
    Ctrl+Shift+C/V         Copy/Paste
    Ctrl+Insert / Shift+Insert Copy/Paste
    Ctrl+Shift+=/-/0       Font size +/-/reset
    Ctrl+Shift+Up/Down     Scroll page up/down
    Ctrl+Shift+Home/End    Scroll top/bottom
    Ctrl+Shift+U           Open screen file
    Mouse select           Auto-copy to clipboard

    ━━━━━━━━━━ NEOVIM: ESSENTIALS ━━━━━━━━━━
    Space           Leader key
    Space ?         Show ALL keybinds (WhichKey)
    Space vc        Vim cheatsheet (floating)
    Space vt        Vim tutor
    Space vk        Search all keymaps
    jk / kj         Exit insert mode
    Esc             Return to Normal mode
    Space w/q/Q     Save / quit / quit all

    ━━━━━━━━ NEOVIM: VS CODE SHORTCUTS ━━━━━━━━
    Ctrl+S          Save (all modes)
    Ctrl+Z          Undo          Ctrl+Y   Redo
    Ctrl+A          Select all
    Ctrl+C / Ctrl+X Copy / Cut (visual)
    Ctrl+V          Paste from clipboard
    Ctrl+D          Duplicate line
    Ctrl+Shift+K    Delete line
    Ctrl+F          Search in file
    Ctrl+G          Go to line
    Ctrl+N          New file
    Ctrl+B          Toggle sidebar
    Ctrl+P          Quick open file
    Ctrl+Shift+P    Command palette
    Ctrl+W q        Close buffer

    ━━━━━━━━━━ NEOVIM: NAVIGATION ━━━━━━━━━━
    Space e         File explorer (Neo-tree)
    Space E         Focus explorer
    -               Parent directory (Oil.nvim)
    s               Flash jump (2-3 keys anywhere)
    S               Flash treesitter select
    Space ff        Find file       Space fg  Grep
    Space fb        Buffers         Space fr  Recent
    Space fc        Commands        Space fh  Help
    Space fk        Keymaps         Space fw  Word
    Space fn        Notifications

    ━━━━━━━━━━ NEOVIM: HARPOON ━━━━━━━━━━
    Space ha        Add file to harpoon
    Space hh        Toggle harpoon menu
    Space h1-h4     Jump to marked file 1-4
    Space hp / hn   Prev / next marked file

    ━━━━━━━━━━ NEOVIM: CODE / LSP ━━━━━━━━━━
    gd  Definition    gD  Declaration
    gr  References    gi  Implementation
    gt  Type def      K   Hover docs
    Ctrl+K          Signature help (n+i)
    Space ca        Code action
    Space cr        Rename symbol
    Space cf        Format file
    Space cd        Line diagnostics
    Space cs        Document symbols
    Space cS        Workspace symbols
    [d / ]d         Prev / next diagnostic

    ━━━━━━━━━━ NEOVIM: LSP INFO ━━━━━━━━━━
    Space li        LSP info
    Space lr        LSP restart
    Space ll        LSP log

    ━━━━━━━━━━ NEOVIM: GIT ━━━━━━━━━━
    Space gg        LazyGit
    Space gn        Neogit
    Space gd        Diff view      Space gD  Close diff
    Space gh        File history   Space gH  Branch history
    Space gb        Line blame     Space gp  Preview hunk
    Space gs        Stage hunk     Space gS  Stage buffer
    Space gr        Reset hunk     Space gR  Reset buffer

    ━━━━━━━━━━ NEOVIM: BUFFERS ━━━━━━━━━━
    Space bd        Delete buffer  Space bD  Force delete
    Space bn        Next           Space bp  Previous
    Space bb        Switch other   Space bo  Close others
    Alt+1-9         Go to buffer 1-9

    ━━━━━━━━━━ NEOVIM: SEARCH ━━━━━━━━━━
    Space sr        Search & Replace (Spectre)
    Space sg        Grep (telescope)
    Space sw        Search word    Space sh  Help
    Space sm        Marks          Space sc  Command history
    /text           Search forward   ?text  Backward
    n / N           Next / prev result
    *               Search word under cursor

    ━━━━━━━━━━ NEOVIM: DIAGNOSTICS ━━━━━━━━━━
    Space xx        All diagnostics
    Space xX        Buffer only
    Space xl        Location list
    Space xq        Quickfix list
    Space xt        TODOs

    ━━━━━━━━━━ NEOVIM: AI ━━━━━━━━━━
    Space ac        Toggle AI chat (local LLM)
    Space aa        Actions menu
    Space ai        Inline prompt
    Space ap        Add selection to chat (visual)

    ━━━━━━━━ NEOVIM: GITHUB (Octo) ━━━━━━━━
    Space opl       List PRs       Space opc  Create PR
    Space oil       List issues    Space oic  Create issue
    Space or        Start review

    ━━━━━━━━━━ NEOVIM: TERMINAL ━━━━━━━━━━
    Space tt        Toggle terminal
    Space tf        Float terminal
    Space th        Horizontal     Space tv  Vertical
    Space tg        LazyGit (float terminal)

    ━━━━━━━━━━ NEOVIM: WINDOWS ━━━━━━━━━━
    Ctrl+H/J/K/L    Navigate windows
    Ctrl+Arrows     Resize windows
    Ctrl+W v        Split vertical
    Ctrl+W s        Split horizontal
    Ctrl+W q        Close window/buffer
    Alt+J/K         Move line up/down

    ━━━━━━━━━━ NEOVIM: TABS ━━━━━━━━━━
    Space Tab n     New tab
    Space Tab d     Close tab
    Space Tab ]     Next tab
    Space Tab [     Previous tab

    ━━━━━━━━━━ NEOVIM: UI TOGGLES ━━━━━━━━━━
    Space un        Toggle line numbers
    Space ur        Toggle relative numbers
    Space uw        Toggle word wrap
    Space us        Toggle spell check
    Space uc        Toggle cursor line
    Space ud        Toggle diagnostics
    Space uh        Toggle inlay hints
    Space uo        Toggle code outline

    ━━━━━━━━━━ NEOVIM: FOLDING ━━━━━━━━━━
    zR              Open all folds
    zM              Close all folds
    zK              Peek fold content

    ━━━━━━━━━ NEOVIM: EDITING TIPS ━━━━━━━━━
    ciw  Change word    diw  Delete word
    cc   Change line    dd   Delete line
    yy   Copy line      p    Paste after
    o    New line below O    New line above
    .    Repeat last     u   Undo
    gc   Toggle comment (visual)
    >  / <             Indent right/left (visual)
    v    Select mode    V    Select lines

    ━━━━━━━━━━━━ THEMES ━━━━━━━━━━━━
    theme-selector <name>  Set theme + rebuild
    theme-selector --list  List available themes
    theme-selector --current  Show active theme
      Themes: ristretto neobrutalist nord
              tokyonight catppuccin

    ━━━━━━━━━━━ SHELL COMMANDS ━━━━━━━━━━━
    rebuild       Rebuild NixOS live (nh os switch .)
    update        Flake update + overlays/skills + switch
    update-apps   Overlays/skills; rebuild only if changed
    update-skills Update all agent skill repos
    update-vscode Update VS Code overlay
    update-claude-code Update Claude Code overlay
    update-opencode Update OpenCode overlay
    update-forgecode Update ForgeCode overlay
    update-codex  Update Codex overlay
    update-runpodctl Update RunPod CLI overlay
    update-pnpm   Update pnpm overlay
    update-llama  Update llama.cpp overlay + rebuild
    update-llama-cpp Alias for update-llama
    secrets       Edit encrypted sops API keys
    secrets-setup Create/edit sops keys helper
    clean         NH garbage collect old generations
    nb / ntest    nh os boot . / nh os test .
    ndiff         nh os build . and show diff
    ll / la       List files (eza)
    cat           bat (syntax highlight)
    v / vim       Neovim
    z <dir>       Smart cd (zoxide)
    Ctrl+R        History search (fzf)

    ━━━━━━━━━━━━━ VPN ━━━━━━━━━━━━━
    vpn              Toggle VPN (default: Portugal)
    vpn <code>       Connect (pt, fr, us, lt)
    vpn off          Disconnect
    vpn status       Show current status
    vpn list         List available servers
    vpn import       Import configs from ~/dotfiles/vpn/
    vpn reset        Remove all and reimport

    ━━━━━━━━━━ GOOGLE CLOUD ━━━━━━━━━━
    gcp-me           Switch to personal account (default config)
    gcp-work         Switch to work account (GCLOUD_WORK_CONFIG or work)
    gcp-who          Show active account + project
    gcp-list         List all gcloud configurations
    gcp-login        Add a new authenticated account
      First-time config setup:
        gcp-login <email>
        gcloud config configurations create <name>
        gcloud config set account <email>
        gcloud config set project <project-id>

    ━━━━━━━ MALWARE ANALYSIS VM ━━━━━━━
    analysis-vm setup             Create lab networks
    analysis-vm install-remnux    REMnux install guide/import
    analysis-vm install-flare     FLARE-VM install guide
    analysis-vm install-devwin    Dev Windows install guide
    analysis-vm <vm> start        Start VM
    analysis-vm <vm> stop         Graceful shutdown
    analysis-vm <vm> killswitch   Force isolation
    analysis-vm <vm> network-on   Temporary NAT for updates
    analysis-vm <vm> verify       Check isolation
    analysis-vm <vm> snapshot     Create snapshot
    analysis-vm <vm> snapshots    List snapshots
    analysis-vm <vm> restore      Restore snapshot
    analysis-vm <vm> status       VM state + network
      VMs: flare remnux devwin
      malware-vm is alias for analysis-vm flare

    ━━━━━━━━━━ PODMAN/CONTAINERS ━━━━━━━━━━
    podman ps              List containers
    podman ps -a           All (incl. stopped)
    podman images          List images
    podman logs <ctr>      Container logs
    podman build -t x .    Build image
    podman compose up -d   Start services
    podman compose down    Stop services
    podman system prune    Clean unused
    lazydocker             Container TUI

    ━━━━━━━━━━ SECURITY TOOLS ━━━━━━━━━━
    nmap -sV <ip>          Port scan + versions
    wireshark              Packet capture GUI
    aircrack-ng            WiFi audit suite
    hashcat                GPU password cracker
    john                   CPU password cracker
    sqlmap                 SQL injection
    hydra                  Brute force login
    ghidra                 Reverse engineering
    cyberchef              Data analysis (GUI)

    ━━━━━━━━━━━━━ GIT ━━━━━━━━━━━━━
    gs         git status
    ga         git add
    gc         git commit
    gp         git push
    gl         git pull
    gd         git diff
    lazygit    Git TUI

    ━━━━━━━━━━━━ AI/LLM ━━━━━━━━━━━━
    llm "prompt"           Chat with active model
    llm 9b                 Chat with Qwen3.5-9B Uncensored
    llm opus               Chat with Qwen3.5-9B Opus Reasoning
    llm ocr <img>          OCR image -> .txt
    llm ocr <img> "Table Recognition:"   OCR table
    llm ocr <img> "Formula Recognition:" OCR formula
    llm local              Start local llama-cpp API helper
    llm server [model]     Start OpenAI-compatible API server
    llm list               List available models
    llm-switch             Show active model + available
    llm-switch status      Show active model/services
    llm-switch opus        Qwen3.5-9B Opus Reasoning (5.6GB)
    llm-switch 9b          Qwen3.5-9B Uncensored (5.6GB)
    llm-switch ocr         GLM-OCR 0.9B (vision, 1.4GB)
    llm-switch stop        Stop LLM service

    ━━━━━━━━━ HERMES AGENT ━━━━━━━━━
    ai                     Chat (local llama-cpp)
    ai-coder               Chat (z.ai GLM-5.1)
    ai-minimax             Chat (MiniMax M1/2.7)
    hermes -p <profile>    Use specific profile
    hermes profile list    List all profiles
    hermes profile create  Create new profile
    hermes /plan           Generate coding plan
    hermes /skills list    List available skills

    ━━━━━━━━ KALI RED TEAM ━━━━━━━━
    kali start             Start container + shell
    kali net               Start network-tools container
    kali shell             Attach to running container
    kali stop              Stop container
    kali build             Build/rebuild image
    kali status            Show container status
    kali destroy           Remove container (data kept)
    kali-ai                AI pentest (local model)
    kali-ai-coder          AI pentest (GLM-5.1)
    kali-ai-minimax        AI pentest (MiniMax M1)

    ━━━━━━━━━ CLAUDE CODE ━━━━━━━━━
    /plan              Plan before coding (waits confirm)
    /blueprint <p> "x" Multi-session construction plan
    /verify            Full check (build+types+lint+tests)
    /verify quick      Build + types only
    /verify pre-commit Pre-commit checks
    /code-review       Security & quality review
    /build-fix         Fix build errors (one at a time)
    /refactor-clean    Detect & remove dead code safely
    /checkpoint create Named git checkpoint
    /checkpoint verify Compare state to checkpoint
    /save-session      Save session for later resumption
    /resume-session    Resume with full context briefing
    /learn             Extract reusable patterns to skills

    ━━━━━━━━━ FORGECODE ━━━━━━━━━
    forge              Start ForgeCode session
    : <prompt>         Send prompt from ZSH (inline)
    :model             Switch model
    :new               New conversation
    :agent             Pick agent
    :provider-login    Add provider API key
    forge zsh doctor   Check ZSH integration

    ━━━━━━━━━━━━━ NIX ━━━━━━━━━━━━━
    nix search nixpkgs <p> Search packages
    nix shell nixpkgs#<p>  Temp install
    nix run nixpkgs#<p>    Run without install
    nix build .#x          Build without result symlink
    nix build -o result .#x Build and keep result symlink
    nix flake update       Update inputs
    nix flake check        Validate flake
    clean-dotfiles-result-links  Remove stale result links
    nix-tree               Visualize deps

    ━━━━━━━━━ MODERN CLI (Rust) ━━━━━━━━━
    eza / ll / la          Better ls
    bat                    Better cat (syntax)
    fd                     Better find
    rg                     Better grep (ripgrep)
    dust                   Better du (disk usage)
    duf                    Better df (filesystems)
    procs                  Better ps
    btop                   System monitor
    zoxide / z             Smart cd

    ━━━━━━━━━━━ DEBUGGING ━━━━━━━━━━━
    gdb                    GNU debugger
    gef                    GDB Enhanced Features
    valgrind               Memory leak detector
    strace                 System call tracer

    ━━━━━━━━━━━━ SYSTEM ━━━━━━━━━━━━
    btop                   System monitor
    audio-restart          Fix audio/headphones
    journalctl -xe         System logs
    systemctl status <s>   Service status
    systemctl --failed     Failed services
    tlp-stat               Battery/power info

    ━━━━━━━━━ STEGANOGRAPHY ━━━━━━━━━
    st3gg encode <f> "msg"  Hide data in image
    st3gg decode <f>        Extract hidden data
    st3gg analyze <f>       Detect hidden data
    st3gg-tui               Terminal UI
    st3gg-web               Browser UI
    stegseek <f> wordlist   Crack steghide passwords

    ━━━━━━━━━━ SDR / RADIO ━━━━━━━━━━
    sdrpp                  SDR++ receiver (modern UI)
    rtl_test               Test RTL-SDR dongle
    rtl_fm -f 98.5M -M fm  FM radio (98.5 MHz)
    rtl_tcp -a 127.0.0.1   Stream SDR over network
    kalibrate-rtl          Calibrate frequency offset
    audacity               Audio analysis
  '';

  keysFile = pkgs.writeText "keys-cheatsheet" keysContent;
  keys-script = pkgs.writeShellScriptBin "keys" "${pkgs.coreutils}/bin/cat ${keysFile}";
in
{
  home.packages = [ keys-script ];
}
