{ ... }: {
  imports = [ ./common.nix ];

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=16
    export DOOM_BIG_FONT_SIZE=24
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "130";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "30";

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

  home.pointerCursor.size = 36;
}
