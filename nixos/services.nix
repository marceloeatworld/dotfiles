{ pkgs, ... }:

{

services.ollama = {
  #package = pkgs.unstable.ollama; # Uncomment if you want to use the unstable channel, see https://fictionbecomesfact.com/nixos-unstable-channel
  enable = false;
  acceleration = "rocm"; # Or "rocm"
  #environmentVariables = { # I haven't been able to get this to work myself yet, but I'm sharing it for the sake of completeness
    # HOME = "/home/ollama";
    # OLLAMA_MODELS = "/home/ollama/models";
    # OLLAMA_HOST = "0.0.0.0:11434"; # Make Ollama accesible outside of localhost
    # OLLAMA_ORIGINS = "http://localhost:8080,http://192.168.0.10:*"; # Allow access, otherwise Ollama returns 403 forbidden due to CORS
  #};
};

  services.xserver.videoDrivers = [ "amdgpu" ];
  # Systemd services setup
  systemd.packages = with pkgs; [
    auto-cpufreq
  ];
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
services.fprintd = {
    enable = true;
    #tod.enable = true;
    #tod.driver = pkgs.libfprint-2-tod1-goodix-550a;
  };
  #services.mpd.enable = true;
  #programs.thunar.enable = true;
  #programs.xfconf.enable = true;
  #services.tumbler.enable = true; 
  #services.fwupd.enable = true;
  services.auto-cpufreq.enable = true;
  hardware.opengl.enable = true;
  # services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
 #services.tlp = {
 #     enable = true;
 #     settings = {
 #     START_CHARGE_THRESH_BAT0 = "75";
 #     STOP_CHARGE_THRESH_BAT0 = "80";
 #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
 #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
 #    CPU_SCALING_MIN_FREQ_ON_AC = "400000";
 #     CPU_SCALING_MAX_FREQ_ON_AC = "8000000"; # not actually
 #     # battery usage does not scale linar to frequency. 
 #     # cutting frequency in half reduces power usage by about two thirds
  #    CPU_SCALING_MIN_FREQ_ON_BAT = "400000";
  #    CPU_SCALING_MAX_FREQ_ON_BAT = "2000000";
  #    CPU_BOOST_ON_AC = "1";
  #    CPU_BOOST_ON_BAT = "0";
  #};
  #};
  services.tlp = {
  enable = true;
  settings = {
    # Seuils de charge de la batterie
    START_CHARGE_THRESH_BAT0 = "75";
    STOP_CHARGE_THRESH_BAT0 = "80";

    # Gouverneur de fréquence CPU
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    # Fréquences CPU minimales et maximales
    CPU_SCALING_MIN_FREQ_ON_AC = "400000"; 
    CPU_SCALING_MAX_FREQ_ON_AC = "4800000"; # Fréquence Boost maximale pour le Ryzen 6800U
    CPU_SCALING_MIN_FREQ_ON_BAT = "400000";
    CPU_SCALING_MAX_FREQ_ON_BAT = "2400000"; # Fréquence de base maximale pour le Ryzen 6800U

    # Boost CPU
    CPU_BOOST_ON_AC = "1"; # Activer le Boost CPU sur secteur
    CPU_BOOST_ON_BAT = "0"; # Désactiver le Boost CPU sur batterie

    # Autres réglages
    PCIE_ASPM_ON_BAT = "powersupersave"; # Économie d'énergie pour les périphériques PCIe sur batterie
    RADEON_POWER_PROFILE_ON_AC = "high"; # Profil de puissance GPU élevé sur secteur
    RADEON_POWER_PROFILE_ON_BAT = "low"; # Profil de puissance GPU faible sur batterie
  };
};


services.printing.enable = true;
services.printing.drivers = [ pkgs.brlaser ];
services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};
}
