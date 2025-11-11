{
  imports = [ ./hardware/laptop.nix ];

  networking.hostName = "bugarela"; # Define your hostname.

  services.libinput.touchpad = {
    naturalScrolling = true;
    accelSpeed = "+0.5";
  };

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

  services.power-profiles-daemon.enable = true;

  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

  #     CPU_MIN_PERF_ON_AC = 0;
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MIN_PERF_ON_BAT = 0;
  #     CPU_MAX_PERF_ON_BAT = 20;

  #     # Optional helps save long term battery health
  #     # START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
  #     # STOP_CHARGE_THRESH_BAT0 = 80;  # 80 and above it stops charging
  #   };
  # };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services.logind.lidSwitch = "hibernate";
  services.logind.lidSwitchExternalPower = "lock";
  services.logind.lidSwitchDocked = "ignore";

}
