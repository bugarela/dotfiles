{
  imports = [ ./hardware/laptop.nix ];

  networking.hostName = "bugarela"; # Define your hostname.

  services.libinput.touchpad.naturalScrolling = true;

  # Xserver basic
  services.xserver = {
    dpi = 144;
    videoDrivers = [ "mesa" ];
  };

  # Backlight control
  programs.light.enable = true;
  services.acpid.enable = true;
  services.acpid.handlers = {
    brightness-up = {
      action = "/run/current-system/sw/bin/light -A 5";
      event = "video/brightnessup.*";
    };
    brightness-down = {
      action = "/run/current-system/sw/bin/light -U 5";
      event = "video/brightnessdown.*";
    };
  };
}
