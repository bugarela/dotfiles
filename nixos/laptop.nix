{
  imports = [ ./hardware/laptop.nix ];

  networking.hostName = "bugarela"; # Define your hostname.

  # Xserver basic
  services.xserver = {
    enable = true;
    exportConfiguration = true;
    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "caps:swapescape";
    dpi = 84;
    videoDrivers = [ "mesa" ];

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
