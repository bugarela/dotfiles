{ pkgs, ... }:
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
  };

  # Backlight control
  hardware.acpilight.enable = true;
  services.acpid.enable = true;
  services.acpid.handlers = {
    brightness-up = {
      action = "/run/current-system/sw/bin/xbacklight -inc 5";
      event = "video/brightnessup.*";
    };
    brightness-down = {
      action = "/run/current-system/sw/bin/xbacklight -dec 5";
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

  services.logind.settings.Login = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";
  };

  systemd.services.lock-before-sleep = {
    description = "Lock screen before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "XDG_SEAT_PATH=/org/freedesktop/DisplayManager/Seat0";
      ExecStart = "${pkgs.lightdm}/bin/dm-tool lock";
    };
  };

  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    lightdm.fprintAuth = true;
    polkit-1.fprintAuth = true;
    "_1password".fprintAuth = true;
  };
}
