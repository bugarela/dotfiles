{
  imports = [
    ./hardware/desktop.nix
  ];

  networking.hostName = "gabriela-nixos"; # Define your hostname.

  # Xserver basic
  services.xserver = {
    enable = true;
    exportConfiguration = true;
    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "caps:swapescape";
    dpi = 141;
    videoDrivers = [ "nvidia" ];

    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };

    displayManager = {
      lightdm.enable = true;
      defaultSession = "xfce";
    };
  };
}
