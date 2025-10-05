{
  imports = [ ./hardware/laptop.nix ];

  networking.hostName = "bugarela"; # Define your hostname.

  services.libinput.touchpad.naturalScrolling = true;

  # Xserver basic
  services.xserver = {
    dpi = 124;
    videoDrivers = [ "mesa" ];
  };

  # Backlight control
  programs.light.enable = true;
  services.acpid.enable = true;
  services.acpid.handlers = {
    brightness-up = {
      action = "/run/current-system/sw/bin/light -A 30";
      event = "video/brightnessup.*";
    };
    brightness-down = {
      action = "/run/current-system/sw/bin/light -U 30";
      event = "video/brightnessdown.*";
    };
  };
}
