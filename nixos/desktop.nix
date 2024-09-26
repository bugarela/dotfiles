{
  imports = [ ./hardware/desktop.nix ];

  networking.hostName = "gabriela-nixos"; # Define your hostname.

  # Xserver basic
  services.xserver = {
    dpi = 141;
    videoDrivers = [ "nvidia" ];
  };

  hardware.nvidia.open = false;
}
