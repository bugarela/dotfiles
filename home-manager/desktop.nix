{ pkgs, ... }: {
  imports = [ ./common.nix ];

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=32
    export DOOM_BIG_FONT_SIZE=42
    export POLYBAR_DPI=192
    export POLYBAR_PADDING_RIGHT=40
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "192";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "40";

  programs.mangohud.enable = true;

  home.packages = [
    pkgs.lutris
    pkgs.bottles
    pkgs.heroic
    pkgs.wine
    # pkgs.tuxguitar

    pkgs.ollama
  ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 30;
          y = 30;
        };
      };

      font = { size = 14.0; };
    };
  };

  home.pointerCursor.size = 48;
}
