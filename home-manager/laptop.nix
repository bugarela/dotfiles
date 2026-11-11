{ config, lib, pkgs, ... }: {
  imports = [ ./common.nix ];

  # Only this destination gets automatic agent forwarding.
  home.file.".ssh/config".text = lib.mkBefore ''
    Host herdr-desktop
        HostName gabriela-nixos
        User gabriela
        IdentityAgent ~/.1password/agent.sock
        ForwardAgent yes
        ServerAliveInterval 15
        ServerAliveCountMax 3
  '';

  # Start explicitly while working remotely; no WantedBy means no forwarding
  # just because the laptop is logged in. Herdr's own SSH connections remain
  # separate, so reconnecting/adding a machine cannot contend for this socket.
  systemd.user.services.herdr-agent-forward = {
    Unit.Description = "Laptop 1Password agent for desktop Herdr Git operations";
    Service = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.openssh}/bin/ssh"
        "-NT"
        "-o BatchMode=yes"
        "-o ForwardAgent=no"
        "-o ControlMaster=no"
        "-o ControlPath=none"
        "-o ExitOnForwardFailure=yes"
        "-R /home/gabriela/.ssh/herdr-laptop-agent.sock:${config.home.homeDirectory}/.1password/agent.sock"
        "herdr-desktop"
      ];
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=36
    export DOOM_BIG_FONT_SIZE=48
    export POLYBAR_DPI=180
    export POLYBAR_PADDING_RIGHT=40
    export QT_SCALE_FACTOR=1.5
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export GDK_SCALE=1.5
    export GDK_DPI_SCALE=1.0
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "180";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "40";
  home.sessionVariables.QT_SCALE_FACTOR = "1.5";
  home.sessionVariables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  home.sessionVariables.GDK_SCALE = "1.5";
  home.sessionVariables.GDK_DPI_SCALE = "1.0";

  home.packages = [
    pkgs.powertop
  ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
      };

      font = {
        size = 10.0;
      };
    };
  };

  home.pointerCursor.size = 42;

  services.picom.backend = "egl";
  services.picom.vSync = true;
}
