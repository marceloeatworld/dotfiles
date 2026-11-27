# Media applications configuration
{ pkgs, config, lib, ... }:

let
  # PhotoGIMP - Makes GIMP look like Photoshop (GIMP 3.0)
  photogimp = pkgs.fetchzip {
    url = "https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip";
    sha256 = "sha256-vBEMR83ZMV/o8wPR9mm2eZt44CulHxdUuK4Y7O/xwzs=";
    stripRoot = false;
  };

  theme = config.theme;

  # Aggregate memory guard for ImageMagick fan-outs. The policy.xml limits
  # below cap each process, but 94 concurrent magick jobs at ~180 MB each
  # still exhausted RAM and swap on 2026-08-28 (OOM killed three Claude
  # sessions). These wrappers route every batch entry point into
  # imagemagick.slice, whose cgroup cap bounds the group as a whole: when the
  # slice hits MemoryMax the kernel kills jobs inside it and nothing else.
  # systemd-run --scope runs the command in the caller's context (stdio, cwd,
  # exit code all pass through); the bus check falls back to a direct exec in
  # environments without a user manager.
  magickGuard = map (name:
    lib.hiPrio (pkgs.writeShellScriptBin name ''
      if [ -S "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus" ]; then
        exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet \
          --slice=imagemagick.slice -- ${pkgs.imagemagick}/bin/${name} "$@"
      fi
      exec ${pkgs.imagemagick}/bin/${name} "$@"
    '')
  ) [ "magick" "convert" "mogrify" "montage" ];
in
{

  # Configure swayimg (WebP-capable image viewer)
  xdg.configFile."swayimg/config".text = ''
    [general]
    position = center
    background = ${theme.colors.background}

    [viewer]
    scale = optimal
    antialiasing = yes
    transparency = grid
  '';

  # ImageMagick resource limits. Without them the pixel cache defaults to the
  # size of RAM, so a single job over many large files (a montage of scan crops,
  # for example) grows until earlyoom starts killing browser tabs to reclaim
  # memory. Capping the cache makes ImageMagick spill instead of taking the
  # machine down with it.
  #
  # This build has HDRI, so every channel is a 32-bit float: one 48-bit 600 dpi
  # A4 master from scan-doc is about 420 MB in the cache. 4 GiB leaves room for
  # multi-step pipelines on a handful of pages while capping any single job.
  # "map" is a memory-mapped file rather than anonymous memory, so the kernel can
  # reclaim it under pressure and it can be larger.
  #
  # temporary-path must not be left at the default /tmp: boot.tmp.useTmpfs makes
  # /tmp a tmpfs, so spilling there would put the overflow straight back into RAM
  # and defeat the limits above. The disk cap keeps a runaway job from filling
  # /home instead; it fails with "cache resources exhausted", which is recoverable.
  xdg.configFile."ImageMagick/policy.xml".text = ''
    <policymap>
      <policy domain="resource" name="memory" value="4GiB"/>
      <policy domain="resource" name="map" value="4GiB"/>
      <policy domain="resource" name="disk" value="32GiB"/>
      <policy domain="resource" name="temporary-path" value="${config.xdg.cacheHome}/ImageMagick"/>
    </policymap>
  '';

  # ImageMagick does not create temporary-path itself; a spill into a missing
  # directory fails the whole operation.
  xdg.cacheFile."ImageMagick/.keep".text = "";

  # Cgroup behind the magickGuard wrappers. MemoryHigh throttles and reclaims
  # first; MemoryMax and MemorySwapMax are the hard walls that keep a fan-out
  # from touching the rest of the machine.
  systemd.user.slices.imagemagick = {
    Unit.Description = "ImageMagick aggregate memory cap";
    Slice = {
      MemoryHigh = "6G";
      MemoryMax = "8G";
      MemorySwapMax = "8G";
    };
  };

  # PhotoGIMP - Only symlink static assets (themes, fonts, shortcuts, etc.)
  # GIMP needs to write to gimprc, sessionrc, pluginrc, etc. so we don't symlink those
  home.file = {
    # Keyboard shortcuts (Photoshop-style)
    # force: GIMP rewrites this symlink into a real file when shortcuts change,
    # so activation tries to back it up and fails on a stale .backup. force
    # re-imposes the PhotoGIMP shortcuts unconditionally (the intent here).
    ".config/GIMP/3.0/shortcutsrc" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/shortcutsrc";
      force = true;
    };
    # Tool presets and options
    ".config/GIMP/3.0/toolrc".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/toolrc";
    ".config/GIMP/3.0/tool-options" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/tool-options";
      recursive = true;
    };
    # Templates
    ".config/GIMP/3.0/templaterc".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/templaterc";
    # Theme styling
    ".config/GIMP/3.0/theme.css".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/theme.css";
    # Splash screens
    ".config/GIMP/3.0/splashes" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/splashes";
      recursive = true;
    };
    # Fonts
    ".config/GIMP/3.0/fonts" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/fonts";
      recursive = true;
    };
    # Gradients
    ".config/GIMP/3.0/gradients" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/gradients";
      recursive = true;
    };
    # Filters
    ".config/GIMP/3.0/filters" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/filters";
      recursive = true;
    };
    # Tags (brush/pattern organization)
    ".config/GIMP/3.0/tags.xml".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/tags.xml";
  };

  # Additional media packages
  home.packages = magickGuard ++ (with pkgs; [
    kdePackages.kdenlive  # Video editor (stable, H.265/HEVC native support)
    flowblade       # Multitrack non-linear video editor
    swayimg         # Image viewer with WebP/AVIF/JXL support (replaces imv)
    ffmpeg-full     # Video/audio/image conversion and processing (includes WebP)
    imagemagick     # Image manipulation CLI
    exiftool        # Read/write EXIF metadata in images
    mediainfo       # Detailed video/audio file information
    v4l-utils       # Video4Linux utilities (v4l2-ctl, v4l2-compliance, etc.)
  ]);
}
