{ pkgs, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];
  # Systemd services setup
  #systemd.packages = with pkgs; [
    #auto-cpufreq
  #];
  services.gnome.gnome-keyring.enable = true;
  # Enable Services
programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryFlavor = "";
  };
  programs.direnv.enable = true;
  services.upower.enable = true;
  programs.zsh.enable = true;
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [
  	#xfce.xfconf
  	gnome2.GConf
  ];
  #services.mpd.enable = true;
  #programs.thunar.enable = true;
  #programs.xfconf.enable = true;
  #services.tumbler.enable = true; 
  #services.fwupd.enable = true;
  #services.auto-cpufreq.enable = true;
  hardware.opengl.enable = true;
  # services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  services.tlp = {
      enable = true;
      settings = {
      START_CHARGE_THRESH_BAT0 = "75";
      STOP_CHARGE_THRESH_BAT0 = "80";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_MIN_FREQ_ON_AC = "400000";
      CPU_SCALING_MAX_FREQ_ON_AC = "8000000"; # not actually
      # battery usage does not scale linar to frequency. 
      # cutting frequency in half reduces power usage by about two thirds
      CPU_SCALING_MIN_FREQ_ON_BAT = "400000";
      CPU_SCALING_MAX_FREQ_ON_BAT = "2000000";
      CPU_BOOST_ON_AC = "1";
      CPU_BOOST_ON_BAT = "0";
  };
  };
  

}
