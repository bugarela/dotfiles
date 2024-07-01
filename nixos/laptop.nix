{
  imports = [ ./hardware/laptop.nix ];

  networking.hostName = "bugarela"; # Define your hostname.

  # Xserver basic
  services.xserver = {
    dpi = 84;
    videoDrivers = [ "mesa" ];
  };
}
